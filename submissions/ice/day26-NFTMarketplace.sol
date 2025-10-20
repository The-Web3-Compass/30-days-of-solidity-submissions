/**
 * @title NFTMarketplace
 * @dev NFT交易市场 - 数字藏品交易平台
 * 
 * 核心功能：
 * 1. 上架NFT：
 *    - 卖家可以设定价格上架自己的NFT
 *    - 支持ETH或其他代币作为支付方式
 *    - 自动检查NFT所有权和授权
 * 
 * 2. 交易机制：
 *    - 买家可以按照标价购买NFT
 *    - 自动处理NFT所有权转移
 *    - 支持多种代币支付（ETH/ERC20）
 * 
 * 3. 费用分配：
 *    - 平台费：2.5%，用于维护平台运营
 *    - 版税费：由NFT创建者设置（最高10%）
 *    - 卖家收入：售价减去平台费和版税
 * 
 * 4. 安全保障：
 *    - NFT托管：交易期间由合约托管
 *    - 防重入保护：避免重复交易
 *    - 所有权验证：确保交易合法性
 * 
 * 5. 市场管理：
 *    - 列表管理：创建、取消、更新
 *    - 版税设置：NFT创建者可设置版税
 *    - 交易记录：完整的上架和交易事件记录
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721Holder, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    // 状态变量
    Counters.Counter private _listingIds;  // 列表ID计数器
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 250; // 平台费率 2.5%
    uint256 public constant FEE_DENOMINATOR = 10000;      // 费用分母

    /**
     * @dev NFT上架信息结构
     * 记录NFT在市场中的完整交易信息
     */
    struct Listing {
        uint256 listingId;        // 唯一标识符
        address nftContract;      // NFT合约地址
        uint256 tokenId;          // NFT编号
        address seller;           // 卖家钱包地址
        address paymentToken;     // 接受的支付代币(0地址表示ETH)
        uint256 price;           // 销售价格
        uint256 royaltyPercentage; // 版税比例(基点：10000=100%)
        bool isActive;           // 上架状态(true=在售)
    }

    /**
     * @dev 核心存储映射
     */
    // 通过上架ID查询NFT信息
    mapping(uint256 => Listing) public listings;              
    // 通过NFT合约地址和tokenId查询当前上架ID
    mapping(address => mapping(uint256 => uint256)) public nftListingId;  
    // 每个NFT合约的默认版税比例
    mapping(address => uint256) public royaltyPercentages;

    /**
     * @dev 市场事件
     * 记录所有重要的市场活动，方便链下监听和数据分析
     */
    // NFT上架事件：记录新的NFT上架信息
    event ListingCreated(
        uint256 indexed listingId,    // 上架ID
        address indexed nftContract,   // NFT合约地址
        uint256 indexed tokenId,      // NFT编号
        address seller,               // 卖家地址
        address paymentToken,         // 支付代币
        uint256 price,                // 价格
        uint256 royaltyPercentage     // 版税比例
    );

    // 取消上架事件：记录NFT下架
    event ListingCancelled(uint256 indexed listingId);

    // 交易完成事件：记录NFT成功售出的完整信息
    event ListingSold(
        uint256 indexed listingId,    // 上架ID
        address indexed nftContract,   // NFT合约地址
        uint256 indexed tokenId,      // NFT编号
        address seller,               // 卖家地址
        address buyer,                // 买家地址
        address paymentToken,         // 支付代币
        uint256 price,                // 成交价格
        uint256 royaltyAmount,        // 版税金额
        uint256 platformFee           // 平台费用
    );

    // 版税设置事件：记录NFT合约的版税变更
    event RoyaltySet(
        address indexed nftContract,   // NFT合约地址
        uint256 percentage            // 新的版税比例
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev 创建NFT列表
     */
    function createListing(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 price
    ) external nonReentrant returns (uint256) {
        require(price > 0, "Price must be greater than zero");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not token owner"
        );
        require(
            IERC721(nftContract).getApproved(tokenId) == address(this) ||
            IERC721(nftContract).isApprovedForAll(msg.sender, address(this)),
            "Not approved for marketplace"
        );

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        // 创建新列表
        listings[listingId] = Listing({
            listingId: listingId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: msg.sender,
            paymentToken: paymentToken,
            price: price,
            royaltyPercentage: royaltyPercentages[nftContract],
            isActive: true
        });

        // 更新NFT到列表ID的映射
        nftListingId[nftContract][tokenId] = listingId;

        // 转移NFT到市场合约
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        emit ListingCreated(
            listingId,
            nftContract,
            tokenId,
            msg.sender,
            paymentToken,
            price,
            royaltyPercentages[nftContract]
        );

        return listingId;
    }

    /**
     * @dev 取消列表
     */
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing not active");
        require(listing.seller == msg.sender, "Not seller");

        // 将NFT返还给卖家
        IERC721(listing.nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        // 更新列表状态
        listing.isActive = false;
        nftListingId[listing.nftContract][listing.tokenId] = 0;

        emit ListingCancelled(listingId);
    }

    /**
     * @dev 购买NFT
     */
    function buyNFT(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing not active");
        require(msg.sender != listing.seller, "Seller cannot buy");

        // 计算费用
        uint256 platformFee = (listing.price * PLATFORM_FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 royaltyAmount = (listing.price * listing.royaltyPercentage) / FEE_DENOMINATOR;
        uint256 sellerAmount = listing.price - platformFee - royaltyAmount;

        // 处理支付
        if (listing.paymentToken == address(0)) {
            // ETH支付
            require(msg.value == listing.price, "Incorrect payment amount");
            
            // 转账平台费用
            (bool platformSuccess,) = payable(owner()).call{value: platformFee}("");
            require(platformSuccess, "Platform fee transfer failed");

            // 转账版税
            if (royaltyAmount > 0) {
                (bool royaltySuccess,) = payable(IERC721(listing.nftContract).ownerOf(0)).call{value: royaltyAmount}("");
                require(royaltySuccess, "Royalty transfer failed");
            }

            // 转账给卖家
            (bool sellerSuccess,) = payable(listing.seller).call{value: sellerAmount}("");
            require(sellerSuccess, "Seller transfer failed");
        } else {
            // ERC20代币支付
            IERC20 paymentToken = IERC20(listing.paymentToken);
            require(
                paymentToken.transferFrom(msg.sender, address(this), listing.price),
                "Payment transfer failed"
            );

            // 转账平台费用
            require(
                paymentToken.transfer(owner(), platformFee),
                "Platform fee transfer failed"
            );

            // 转账版税
            if (royaltyAmount > 0) {
                require(
                    paymentToken.transfer(IERC721(listing.nftContract).ownerOf(0), royaltyAmount),
                    "Royalty transfer failed"
                );
            }

            // 转账给卖家
            require(
                paymentToken.transfer(listing.seller, sellerAmount),
                "Seller transfer failed"
            );
        }

        // 转移NFT给买家
        IERC721(listing.nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        // 更新列表状态
        listing.isActive = false;
        nftListingId[listing.nftContract][listing.tokenId] = 0;

        emit ListingSold(
            listingId,
            listing.nftContract,
            listing.tokenId,
            listing.seller,
            msg.sender,
            listing.paymentToken,
            listing.price,
            royaltyAmount,
            platformFee
        );
    }

    /**
     * @dev 设置NFT合约的版税比例
     */
    function setRoyaltyPercentage(address nftContract, uint256 percentage) external {
        require(
            IERC721(nftContract).ownerOf(0) == msg.sender,
            "Not NFT contract owner"
        );
        require(percentage <= 1000, "Royalty too high"); // 最高10%

        royaltyPercentages[nftContract] = percentage;
        emit RoyaltySet(nftContract, percentage);
    }

    /**
     * @dev 获取列表信息
     */
    function getListing(uint256 listingId) external view returns (
        address nftContract,
        uint256 tokenId,
        address seller,
        address paymentToken,
        uint256 price,
        uint256 royaltyPercentage,
        bool isActive
    ) {
        Listing storage listing = listings[listingId];
        return (
            listing.nftContract,
            listing.tokenId,
            listing.seller,
            listing.paymentToken,
            listing.price,
            listing.royaltyPercentage,
            listing.isActive
        );
    }

    /**
     * @dev 获取NFT当前列表ID
     */
    function getListingId(address nftContract, uint256 tokenId) external view returns (uint256) {
        return nftListingId[nftContract][tokenId];
    }

    /**
     * @dev 获取NFT合约的版税比例
     */
    function getRoyaltyPercentage(address nftContract) external view returns (uint256) {
        return royaltyPercentages[nftContract];
    }
}