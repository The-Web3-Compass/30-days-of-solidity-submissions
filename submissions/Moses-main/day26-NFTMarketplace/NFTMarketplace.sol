// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A self-contained NFT marketplace contract that can:

// - List any ERC-721
// - Sell it for ETH
// - Distribute fees
// - Transfer the NFT securely
// - Log all activity with events for frontends to pick up

// It’s like your own little OpenSea — but on your terms.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Import ReentrancyGuard to avoid bugs in ERC721 contracts. 
// Useful for preventing duplicate NFT sales or multiple transactions on a single contract.contract NFTMarketplace is ReentrancyGuard {
contract NFTMarketplace is ReentrancyGuard {
    address public owner;
    uint256 public marketplaceFeePercent; // in basis points (100 = 1%)
    address public feeRecipient;

    struct Listing{
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price; 
        uint256 royaltyReciever;
        uint256 royaltyPercent; //in basis points
        bool isListed;
    }
    
    // mapping(address => Listing[]) public listings;// this allows a contract to have more than one NFT marketplace. We will use this to list more than one nfts on the market place at once. This is an array of NFT listings
    //                                              // we can map the address of the NFT (address(0)) with an array of Listing structs
    // mapping(uint256 => uint96) public tokenPrice;// price of a given nft is stored in this mapping, and it is indexed by its tokenId
     mapping(address => mapping(uint256 => Listing)) public listings;

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
    

    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Market place fee is too high. (max 10%)");
        require(_feeRecipient != address(0), "Fee recipient cannot be zero");

        owner = msg.sender;
        marketplaceFeePercent = _marketplaceFeePercent;
        feeRecipient = _feeRecipient;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Marketplace fee too high");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid fee recipient");
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
        require(price > 0, "Price must be above zero");
        require(royaltyPercent <= 1000, "Max 10% royalty allowed");
        require(!listings[nftAddress][tokenId].isListed, "Already listed");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
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

     {
        Listing memory item = listings[nftAddress][tokenId];
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

    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not the seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

    receive() external payable {
        revert("Direct ETH not accepted");
    }

    fallback() external payable {
        revert("Unknown function");
    }
}
