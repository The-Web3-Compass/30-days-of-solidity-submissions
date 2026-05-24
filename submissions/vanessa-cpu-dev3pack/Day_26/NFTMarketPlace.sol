// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    address public owner;
    uint256 public marketplaceFeePercent = 250; // 2.5% fee (basis points)
    address public feeRecipient;

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        bool isListed;
    }

    // NFT Address -> Token ID -> Listing
    mapping(address => mapping(uint256 => Listing)) public listings;
    
    // Revenue collected by the marketplace
    uint256 public feesCollected;

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    constructor(address _feeRecipient) {
        owner = msg.sender;
        feeRecipient = _feeRecipient;
    }

    /////////////////////
    // MAIN FUNCTIONS //
    ////////////////////

    /*
     * @notice Method for listing your NFT on the marketplace
     * @param nftAddress: Address of the NFT
     * @param tokenId: The Token ID of the NFT
     * @param price: sale price of the listed NFT
     */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant {
        require(price > 0, "Price must be greater than 0");
        
        // 1. Check if the marketplace is approved to move the NFT
        IERC721 nft = IERC721(nftAddress);
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Not approved for marketplace");
        
        // 2. Check ownership
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

        // 3. Create the listing
        listings[nftAddress][tokenId] = Listing(msg.sender, nftAddress, tokenId, price, true);
        
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /*
     * @notice Method for buying a listing
     * @param nftAddress: Address of the NFT
     * @param tokenId: The Token ID of the NFT
     */
    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listedItem = listings[nftAddress][tokenId];
        require(listedItem.isListed, "Item not listed");
        require(msg.value == listedItem.price, "Price not met");

        // 1. Calculate Fees
        // Fee for the marketplace
        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        // Amount for the seller
        uint256 sellerAmount = msg.value - feeAmount;

        // 2. Update State (Delete listing BEFORE transfer to prevent reentrancy)
        delete listings[nftAddress][tokenId];
        feesCollected += feeAmount;

        // 3. Transfer Money
        // Pay the seller
        (bool success, ) = payable(listedItem.seller).call{value: sellerAmount}("");
        require(success, "Transfer to seller failed");

        // 4. Transfer NFT
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external nonReentrant {
        Listing memory listedItem = listings[nftAddress][tokenId];
        require(listedItem.seller == msg.sender, "Not the seller");
        require(listedItem.isListed, "Not listed");

        delete listings[nftAddress][tokenId];
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function withdrawFees() external {
        require(msg.sender == owner, "Only owner");
        (bool success, ) = payable(feeRecipient).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}