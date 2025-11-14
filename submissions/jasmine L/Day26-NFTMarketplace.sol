// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard{
    address public owner;//可以更新费用，更改费用接收者
    uint256 public marketplaceFeePercent;//平台费用收取，以基点为单位100
    address public feeRecipient;//费用由谁负责接收：智能合约、市场创始人、多重签名钱包、DAO金库

    struct Listing{
        address seller;//最终收款人
        address nftAddress;//NFT合约地址
        uint256 tokenId;//NFT的ID
        uint256 price;//卖家想卖的价格
        address royaltyReceiver;//允许创作者从二次销售中赚钱，当她们不再是买家
        uint256 royaltyPercent;//应该获得多少版税
        bool isListed;// NFT是否当前列出，可以控制前端显示，检查其是否在售
    }

    mapping (address => mapping (uint256 => Listing)) public listings;// NFT合约地址，代币Id

    
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

    constructor(uint256 _marketplaceFeePercent, address _feeRecipient){
        require(_marketplaceFeePercent <= 1000, "Marketplace fee too high max 10%");
        require(_feeRecipient != address(0), "Fee recipient is not exist");

        owner = msg.sender;
        marketplaceFeePercent = _marketplaceFeePercent;
        feeRecipient = _feeRecipient;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "no owner permission");
        _;
    }

    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner{
        require(_newFee <= 1000, "Marketplace fee too high max 10%");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner{
        require(_newRecipient != address(0), "Fee recipient is not exist");
        feeRecipient = _newRecipient;
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);

    }

    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,//允许创作者从二次销售中赚钱，当她们不再是买家
        uint256 royaltyPercent//应该获得多少版税
    )external {
        require(price > 0 ,"Price must > 0");
        require(royaltyPercent <= 1000, "royaltyPercent fee too high max 10%");
        require(!listings[nftAddress][tokenId].isListed, "Already listed");

        IERC721 nft = IERC721(nftAddress);//为了方便调用 `ownerOf``getApproved` `isApprovedForAll`
        require(nft.ownerOf(tokenId) == msg.sender, "Not Owner");
        require(nft.getApproved(tokenId)==address(this) || nft.isApprovedForAll(msg.sender,address(this)), "Marketplace have no permission to handle this NFT");

        listings[nftAddress][tokenId] = Listing({
            seller:msg.sender,
            nftAddress: nftAddress,
            tokenId:tokenId,
            price:price,
            royaltyReceiver:royaltyReceiver,
            royaltyPercent:royaltyPercent,
            isListed:true
        });//将自己的NFT放入mapping，以平台为中介，进行售卖
        emit Listed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);

    }

    function buyNFT(address nftAddress, uint256 tokenId)external payable nonReentrant {
        Listing memory item = listings[nftAddress][tokenId];
        require(!item.isListed, "Not listed");
        require(msg.value == item.price, "Incorrct ETH price");
        require(item.royaltyPercent + marketplaceFeePercent <= 10000, "Combined fees exceed 100%");
        //不太理解这一块，之前奢姿的时候每个都不超10%，两个加起来不超过20%，怎么会有这个破坏行动呢？

        uint256 feeAmount = (msg.value * marketplaceFeePercent)/10000;
        uint256 royaltyAmount = (msg.value * item.royaltyPercent)/10000;
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;//去掉这些费用看看还剩多少钱

        if(feeAmount > 0){
            payable (feeRecipient).transfer(feeAmount);
        }

        if(royaltyAmount > 0 && item.royaltyReceiver != address(0)){
            payable (item.royaltyReceiver).transfer(royaltyAmount);
        }
        payable(item.seller).transfer(sellerAmount);

        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);
        delete listings[nftAddress][tokenId];

        emit Purchase(msg.sender, nftAddress, tokenId, msg.value, item.seller, item.royaltyReceiver, royaltyAmount, feeAmount);

    }

    function cancelListing(address nftAddress, uint256 tokenId)external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not the seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    function getListing(address nftAddress, uint256 tokenId)external view returns(Listing memory){
        return listings[nftAddress][tokenId];
    }

    receive() external payable { 
        revert("Direct ETH not accepted");
    }

    fallback() external payable {
        revert("Unknown function");
     }








}