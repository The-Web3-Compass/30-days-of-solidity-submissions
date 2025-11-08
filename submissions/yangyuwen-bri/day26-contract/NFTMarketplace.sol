// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 引入OpenZeppelin的ERC721接口和重入保护模块
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title NFT Marketplace - 一个支持任意ERC721的NFT交易市场
/// @notice 支持上架、购买、取消、版税、手续费分配，安全防重入
contract NFTMarketplace is ReentrancyGuard {
    // 管理员地址
    address public owner;
    // 市场手续费（基点，100=1%）
    uint256 public marketplaceFeePercent;
    // 手续费收款地址
    address public feeRecipient;

    /// @notice NFT挂单信息结构体
    struct Listing {
        address seller;           // 卖家地址
        address nftAddress;       // NFT合约地址
        uint256 tokenId;          // NFT的tokenId
        uint256 price;            // 售价（单位：wei）
        address royaltyReceiver;  // 版税收款人
        uint256 royaltyPercent;   // 版税比例（基点，100=1%）
        bool isListed;            // 是否在售
    }

    // 所有NFT的挂单信息（nft合约地址 => tokenId => 挂单详情）
    mapping(address => mapping(uint256 => Listing)) public listings;

    // 事件定义
    event Listed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    );
    event Purchase(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address royaltyReceiver,
        uint256 royaltyAmount,
        uint256 marketplaceFeeAmount
    );
    event Unlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event FeeUpdated(
        uint256 newMarketplaceFee,
        address newFeeRecipient
    );

    /// @notice 构造函数，初始化市场参数
    /// @param _marketplaceFeePercent 市场手续费（基点，100=1%）
    /// @param _feeRecipient 手续费收款地址
    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Marketplace fee too high (max 10%)");
        require(_feeRecipient != address(0), "Fee recipient cannot be zero");
        owner = msg.sender;
        marketplaceFeePercent = _marketplaceFeePercent;
        feeRecipient = _feeRecipient;
    }

    /// @notice 仅限管理员操作的修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @notice 设置市场手续费比例
    /// @param _newFee 新手续费（基点，100=1%）
    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Marketplace fee too high");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    /// @notice 设置手续费收款地址
    /// @param _newRecipient 新收款地址
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _newRecipient;
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);
    }

    /// @notice 上架NFT
    /// @param nftAddress NFT合约地址
    /// @param tokenId NFT的tokenId
    /// @param price 售价（单位：wei）
    /// @param royaltyReceiver 版税收款人
    /// @param royaltyPercent 版税比例（基点，100=1%）
    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    ) external {
        require(price > 0, "Price must be above zero");
        require(royaltyPercent <= 1000, "Max 10% royalty allowed");
        require(!listings[nftAddress][tokenId].isListed, "Already listed");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            royaltyReceiver: royaltyReceiver,
            royaltyPercent: royaltyPercent,
            isListed: true
        });

        emit Listed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);
    }

    /// @notice 购买NFT，自动分配ETH给卖家、创作者和平台
    /// @param nftAddress NFT合约地址
    /// @param tokenId NFT的tokenId
    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(msg.value == item.price, "Incorrect ETH sent");
        require(item.royaltyPercent + marketplaceFeePercent <= 10000, "Combined fees exceed 100%");

        // 计算各方分成
        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

        // 平台手续费
        if (feeAmount > 0) {
            payable(feeRecipient).transfer(feeAmount);
        }
        // 创作者版税
        if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }
        // 卖家收入
        payable(item.seller).transfer(sellerAmount);

        // NFT转移
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        // 删除挂单
        delete listings[nftAddress][tokenId];

        emit Purchase(
            msg.sender,
            nftAddress,
            tokenId,
            msg.value,
            item.seller,
            item.royaltyReceiver,
            royaltyAmount,
            feeAmount
        );
    }

    /// @notice 卖家取消NFT挂单
    /// @param nftAddress NFT合约地址
    /// @param tokenId NFT的tokenId
    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not the seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    /// @notice 查询NFT挂单详情
    /// @param nftAddress NFT合约地址
    /// @param tokenId NFT的tokenId
    /// @return 挂单详情
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

    /// @notice 拒绝直接转账ETH到合约
    receive() external payable {
        revert("Direct ETH not accepted");
    }

    /// @notice 拒绝未知函数调用
    fallback() external payable {
        revert("Unknown function");
    }
}
