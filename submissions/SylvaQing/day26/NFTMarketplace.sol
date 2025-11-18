// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// 调用day21的SimpleNFT
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {

    address public owner; //谁负责
    uint256 public marketplaceFeePercent; // 以基点为单位 (100 = 1%)
    address public feeRecipient; //费用去哪里
    // 市场上列出的单个NFT的迷你数据库条目
    struct Listing {
        address seller; //接收大部分付款的人（在市场费用和版税之后）
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver; //接收创作者版税的地址，允许创作者继续从二次销售中赚钱
        uint256 royaltyPercent; // 获得多少版税，以基点为单位
        bool isListed;
    }
    
    // NFT是否当前列出的标志
    bool isListed;

    
    // listings[nftAddress][tokenId]
    mapping(address => mapping(uint256 => Listing)) public listings;

    // 事件
    // 当NFT被列出出售时发出此事件
    event Listed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    );
    // 当有人购买NFT时触发此事件
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
    // 当卖家取消他们的列表时发出
    event Unlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    // 当市场所有者更改费用设置时记录此事件
    event FeeUpdated(
        uint256 newMarketplaceFee,
        address newFeeRecipient
    );

    // 构造函数——引导市场
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

    //===========具体函数==============//
    // 更新市场费用
    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Marketplace fee too high");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }
    // 更新市场费用去向
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _newRecipient;
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);
    }

    // 列出你的NFT出售
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

        // 与NFT交互：调用标准ERC-721函数
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        // 在链上保存列表信息
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

    // 用ETH购买NFT
    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(msg.value == item.price, "Incorrect ETH sent");
        require(
            item.royaltyPercent + marketplaceFeePercent <= 10000,
            "Combined fees exceed 100%"
        );

        // 总ETH（msg.value）分成三个桶：-市场费用；创作者版税；卖家的实际收入
        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

        // 支付市场:平台、DAO，甚至开发钱包。
        if (feeAmount > 0) {
            payable(feeRecipient).transfer(feeAmount);
        }

        // 支付创作者版税:如果列表有版税信息，指定地址获得一部分
        if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }

        // 支付卖家:费用和版税后剩下的任何东西都归列出NFT的人
        payable(item.seller).transfer(sellerAmount);

        // 将NFT转移给买家
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        // 清理列表:一旦NFT被出售，我们从存储中删除列表，这样它就不再显示为"出售"。
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

    // 从销售中移除NFT:只有原始卖家可以取消列出
    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not the seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    //===========工具函数===========//
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }
    // 拒绝直接ETH转账
    receive() external payable {
        revert("Direct ETH not accepted");
    }
    // 拒绝未知函数调用
    fallback() external payable {
        revert("Unknown function");
    }

}