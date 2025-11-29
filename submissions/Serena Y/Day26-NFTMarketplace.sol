
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {//保护我们的合约免受称为重入攻击的常见黑客攻击
    address public owner;//部署合约的地址
    uint256 public marketplaceFeePercent; //市场将从每次销售中收取的费用百分比  以基点为单位 (100 = 1%)
    address public feeRecipient;//每次NFT销售中接收市场份额的钱包

    struct Listing {//Listing结构体 列出的单个NFT的迷你数据库条目
        address seller;//列出NFT的人
        address nftAddress;//NFT的合约地址
        uint256 tokenId;//NFT的ID
        uint256 price;//NFT的金额
        address royaltyReceiver;//创作者版税的地址
        uint256 royaltyPercent; // 应该获得多少版税——以基点为单位（1% = 100）以基点为单位
        bool isListed;//告诉我们NFT是否当前列出的标志
    }

    mapping(address => mapping(uint256 => Listing)) public listings;//映射 NFT合约地址 NFT ID 来访问NFT列表

    event Listed(//当NFT被列出出售时发出此事件
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    );

    event Purchase(//当有人购买NFT时触发此事件
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address royaltyReceiver,
        uint256 royaltyAmount,
        uint256 marketplaceFeeAmount
    );

    event Unlisted(//当卖家取消他们的列表时发出。
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event FeeUpdated(//当市场所有者更改费用设置时记录此事件
        uint256 newMarketplaceFee,
        address newFeeRecipient
    );

    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Marketplace fee too high (max 10%)");//防止在部署时设置疯狂的费用设置
        require(_feeRecipient != address(0), "Fee recipient cannot be zero");//费用接收者检查 不能为0

        owner = msg.sender;//部署合约的人成为管理员/所有者
        marketplaceFeePercent = _marketplaceFeePercent;//marketplaceFeePercent：平台从每次销售中收取多少
        feeRecipient = _feeRecipient;//feeRecipient：费用发送到哪里
    }

    modifier onlyOwner() {//锁定管理函数
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {// 更新市场费用
        require(_newFee <= 1000, "Marketplace fee too high");//新的市场费用应该小于百分之10 不要设置太高
        marketplaceFeePercent = _newFee;//更新状态
        emit FeeUpdated(_newFee, feeRecipient);//发出事件
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {//更新市场费用去向
        require(_newRecipient != address(0), "Invalid fee recipient");//新的市场费接收人地址不为0
        feeRecipient = _newRecipient;//更新状态
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);//发出事件
    }

    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    ) external {
        require(price > 0, "Price must be above zero");//NFT的价格大于0
        require(royaltyPercent <= 1000, "Max 10% royalty allowed");//作者的版权税应该小于1000
        require(!listings[nftAddress][tokenId].isListed, "Already listed");//需要这个NFT之前没有被列出来

        IERC721 nft = IERC721(nftAddress);//将一个已知的地址（nftAddress）视为一个 IERC721 标准的智能合约实例，并将其赋值给一个名为 nft的变量，以便调用该合约的方法。
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");//确保调用者实际拥有他们试图列出的NFT
        require(//市场必须被批准代表用户转移NFT
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listings[nftAddress][tokenId] = Listing({//创建一个Listing结构体并将其存储在我们的嵌套listings映射中
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            royaltyReceiver: royaltyReceiver,
            royaltyPercent: royaltyPercent,
            isListed: true
        });

        emit Listed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);//发出事件
    }

    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {//用ETH购买NFT
        Listing memory item = listings[nftAddress][tokenId];//从存储中获取列表到内存中，以便我们可以读取其详细信息
        require(item.isListed, "Not listed");//NFT需要被列出
        require(msg.value == item.price, "Incorrect ETH sent");//价格需要满足要求
        require(
            item.royaltyPercent + marketplaceFeePercent <= 10000,//原作者版税和市场收取的税需要小于百分之一百
            "Combined fees exceed 100%"
        );

        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;//市场收取得 等于 付款*市场税率
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;//原作者税率登月 付款金额*原创税
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;//卖家收到得钱等于 付款减去市场和原创税

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

    function cancelListing(address nftAddress, uint256 tokenId) external {//这个函数让NFT的卖家在出售之前从市场中移除它
        Listing memory item = listings[nftAddress][tokenId];//加载列表
        require(item.isListed, "Not listed");//果NFT没有列出，你不能取消它
        require(item.seller == msg.sender, "Not the seller");//只有原始卖家可以取消他们的列表。

        delete listings[nftAddress][tokenId];//删除列表
        emit Unlisted(msg.sender, nftAddress, tokenId);//公告事件
    }

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {//查看列表详细信息
        return listings[nftAddress][tokenId];
    }

    receive() external payable {//拒绝直接ETH转账
        revert("Direct ETH not accepted");
    }

    fallback() external payable {//拒绝未知函数调用
        revert("Unknown function");
    }
}

