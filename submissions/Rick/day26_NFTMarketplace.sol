// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/* 
    @title NFT 交易市场
    nft的上下架
    费率设置
    市场受益人设置

    ReentrancyGuard 防止重入攻击
*/
contract NFTMarketplace is ReentrancyGuard {
    // 市场管理者
    address public owner;
    // 市场费率 基点为单位
    uint256 public marketplaceFeePercent; 
    // 市场费率受益人
    address public feeRecipient;

    // NFT 产品详情
    struct  NFTItem{
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver;
        uint256 royaltyPercent; // in basis points
        bool isListed;
    }
    // 市场产品集合
    mapping(address => mapping(uint256 => NFTItem)) public listings;

    // NFT上架
    event Listed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    );
    // 购买NFT
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
    // NFT下架
    event Unlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    // 调整市场费率
    event FeeUpdated(
        uint256 newMarketplaceFee,
        address newFeeRecipient
    );

    
    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Marketplace fee too high (max 10%)");
        require(_feeRecipient != address(0), "Fee recipient cannot be zero");

        owner = msg.sender;
        marketplaceFeePercent = _marketplaceFeePercent;
        feeRecipient = _feeRecipient;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // 设置市场费率
    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Marketplace fee too high");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    // 设置市场受益人
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _newRecipient;
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);
    }

    // 新增NFT上架
    function addNFT(
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
        // 校验nft归属
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        // 校验nft授权是否成功
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listings[nftAddress][tokenId] = NFTItem({
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
        NFTItem memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(msg.value == item.price, "Incorrect ETH sent");
        require(
            item.royaltyPercent + marketplaceFeePercent <= 10000,
            "Combined fees exceed 100%"
        );

        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

        // Marketplace fee
        if (feeAmount > 0) {
            payable(feeRecipient).transfer(feeAmount);
        }

        // Creator royalty
        if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }

        // Seller payout
        payable(item.seller).transfer(sellerAmount);

        // Transfer NFT to buyer
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        // Remove listing
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
    // NFT下架
    function cancelListing(address nftAddress, uint256 tokenId) external {
        NFTItem memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not the seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }
    // 查询NFT详情
    function getListing(address nftAddress, uint256 tokenId) external view returns (NFTItem memory) {
        return listings[nftAddress][tokenId];
    }
    // 拒绝直接转账
    receive() external payable {
        revert("Direct ETH not accepted");
    }
    // 拒绝其他未知函数调用
    fallback() external payable {
        revert("Unknown function");
    }
}
