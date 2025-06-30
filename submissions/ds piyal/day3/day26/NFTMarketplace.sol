// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    address public owner;
    uint256 public marketplaceFeePercent;
    address public feeRecipient;

    struct Listing{
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver;
        uint256 royaltyPercent;
        bool isListed;
    }
        mapping (address => mapping(uint256 => Listing)) public listings;

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
    require(_marketplaceFeePercent <= 1000,"Marketplace fee too high (max 10%)");
    require(_feeRecipient != address(0),"Fee recipient is zero address");

    owner = msg.sender;
    marketplaceFeePercent = _marketplaceFeePercent;
    feeRecipient = _feeRecipient;
}

modifier onlyOwner() {
    require(msg.sender == owner,"Only the contract owner can call this function");
    _;
}

function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner{
    require(_newFee <= 1000,"Marketplace fee too high (max 10%)");
    marketplaceFeePercent = _newFee;
    emit FeeUpdated(_newFee, feeRecipient);
}

function setFeeRecipient(address _newRecipient) external onlyOwner{
    require(_newRecipient != address(0),"Invalid fee recipient");
    feeRecipient = _newRecipient;
    emit FeeUpdated(marketplaceFeePercent, _newRecipient);
}

function listNFT(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    address royaltyReceiver,
    uint256 royaltyPercent 
) external {
    require(price > 0,"Price must be above zero");
    require(royaltyPercent <= 1000,"Royalty percent too high (max 10%)");
    require(!listings[nftAddress][tokenId].isListed,"Already listed");
    require(nftAddress != address(0),"Invalid NFT contract address");

    IERC721 nft = IERC721(nftAddress);
    require(nft.ownerOf(tokenId) == msg.sender,"Not the owner");
    require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),"Marketplace not approved");
    
    require(royaltyPercent + marketplaceFeePercent <= 10000,"Combined fees exceed 100%");

    listings[nftAddress][tokenId] = Listing({
        seller : msg.sender,
        nftAddress : nftAddress,
        tokenId : tokenId,
        price : price,
        royaltyReceiver : royaltyReceiver,
        royaltyPercent : royaltyPercent,
        isListed : true
    });
    emit Listed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);
}

   function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant{
    Listing memory item = listings[nftAddress][tokenId];
    require(item.isListed,"Not listed");
    require(msg.value == item.price,"Incorrect ETH sent");
    require(item.royaltyPercent + marketplaceFeePercent <= 10000,"Combined fees exceed 100%");
    
    IERC721 nft = IERC721(item.nftAddress);
    require(nft.ownerOf(item.tokenId) == item.seller,"Seller no longer owns NFT");
    require(nft.getApproved(item.tokenId) == address(this) || nft.isApprovedForAll(item.seller, address(this)),"NFT approval revoked");

    uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
    uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
    uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

    delete listings[nftAddress][tokenId];
    
    nft.safeTransferFrom(item.seller, msg.sender, item.tokenId);

    bool success;
    if(feeAmount > 0){
        (success, ) = payable(feeRecipient).call{value: feeAmount}("");
        require(success, "Fee transfer failed");
    }
    if(royaltyAmount > 0 && item.royaltyReceiver != address(0)){
        (success, ) = payable(item.royaltyReceiver).call{value: royaltyAmount}("");
        require(success, "Royalty transfer failed");
    }
    (success, ) = payable(item.seller).call{value: sellerAmount}("");
    require(success, "Seller payment failed");

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
     
function cancelListing(address nftAddress, uint256 tokenId) external {
    Listing memory item = listings[nftAddress][tokenId];
    require(item.isListed,"Not listed");
    require(item.seller == msg.sender,"Not the seller");

    delete listings[nftAddress][tokenId];
    emit Unlisted(msg.sender, nftAddress, tokenId);
}

function getListing(address nftAddress, uint256 tokenId) external view returns(Listing memory){
    return listings[nftAddress][tokenId];
}

receive() external payable{
    revert("Direct ETH not accepted");
}

fallback() external payable {
    revert("Unknown function");
}
}