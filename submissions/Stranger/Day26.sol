
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    // 合约属主, 市场销售费率, 接收市场销售费用的钱包
    address public owner;
    uint256 public marketplaceFeePercent; // 以基点为单位 (100 = 1%)
    address public feeRecipient;

    // 定义"列出"结构体
    struct Listing {
        address seller;          // 卖家
        address nftAddress;      // NFT 合约的地址
        uint256 tokenId;         // NFT 的ID
        uint256 price;           // NFT 的价格
        address royaltyReceiver; // 接收创作者版税的地址
        uint256 royaltyPercent;  // 版税费率, 以基点为单位
        bool isListed;           // 是否列出(出售)
    }

    // 所有列出的映射, NFT 合约地址 -> （NFT ID -> Listing）
    mapping(address => mapping(uint256 => Listing)) public listings;

    // NFT 列出事件
    event Listed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    );

    // NFT 购买事件
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

    // 取消NFT 列出事件
    event Unlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    // 销售市场管理人修改销售费率或者费用接收地址事件
    event FeeUpdated(
        uint256 newMarketplaceFee,
        address newFeeRecipient
    );

    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Marketplace fee too high (max 10%)");
        require(_feeRecipient != address(0), "Fee recipient cannot be zero");

        owner = msg.sender;  // 部署合约的人为合约属主
        marketplaceFeePercent = _marketplaceFeePercent;  // 销售市场的销售费率抽成
        feeRecipient = _feeRecipient;                    // 销售费用接收地址
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // 更新市场销售费率
    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Marketplace fee too high");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    // 更新市场销售费用接收地址
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _newRecipient;
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);
    }

    // 列出 NFT
    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    ) external {
        // 验证NFT的出售价格, 版税费率, 以及NFT是否已经列出
        require(price > 0, "Price must be above zero");
        require(royaltyPercent <= 1000, "Max 10% royalty allowed");
        require(!listings[nftAddress][tokenId].isListed, "Already listed");

        // 基于NFT的地址获取IERC721 的标准接口以便调用相关函数
        IERC721 nft = IERC721(nftAddress);
        // 只有NFT的属主才能列出 NFT
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        // 检查本合约是否被授权转移NFT
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        // 在列表中添加新列出的 NFT
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

    // 购买NFT
    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        // 获取NFT 信息
        Listing memory item = listings[nftAddress][tokenId];
        // 检查NFT列出状态, 购买金额是否与出售价格匹配, 版税及市场销售费率总和是否合理(若超过10000则销售费用不足以支付刚性费用)
        require(item.isListed, "Not listed");
        require(msg.value == item.price, "Incorrect ETH sent");
        require(
            item.royaltyPercent + marketplaceFeePercent <= 10000,
            "Combined fees exceed 100%"
        );

        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;   // 由销售市场收取的销售费用
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000; // 由NFT 创作者收取的版税
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;      // 由卖家获取的销售收入

        // 市场费用
        if (feeAmount > 0) {
            payable(feeRecipient).transfer(feeAmount);
        }

        // 创作者版税
        if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }

        // 卖家支付
        payable(item.seller).transfer(sellerAmount);

        // 将NFT转移给买家
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        // 删除列表
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

    // 取消NFT 列出
    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not the seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    // 查询特定NFT的列出信息
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

    // 拒绝直接转账
    receive() external payable {
        revert("Direct ETH not accepted");
    }

    // 拒绝未知调用
    fallback() external payable {
        revert("Unknown function");
    }
}

