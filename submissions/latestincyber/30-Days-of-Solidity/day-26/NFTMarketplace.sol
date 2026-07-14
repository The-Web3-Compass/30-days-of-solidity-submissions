// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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

    // revenue collected by the marketplace
    uint256 public feesCollected;

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    constructor(address _feeRecipient) {
        owner = msg.sender;
        feeRecipient = _feeRecipient;
    }

    // MAIN FUNCTIONS

    /*
     * @notice method for listing your NFT on the marketplace
     * @param tokenId: the token ID of the NFT
     * @param price: sale price of the listed NFT
     */
    function listItem(
        address nftAddress,
        uint256 tokenId, 
        uint256 price
    ) public nonReentrant {
        require(price > 0, "Price must be greater than 0");

        // 1. check if the marketplace is approved to move the NFT
        IERC721 nft = IERC721(nftAddress);
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Not approved for marketplace");

        // 2. chcek ownership
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

        // 3. create the listing
        listings[nftAddress][tokenId] = Listing(msg.sender, nftAddress, tokenId, price, true);

        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /*
     * @notice method for buying a listing
     * @param nftAddress: address of the NFT
     * @param tokenId: the token ID of the NFT
     */
    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listedItem = listings[nftAddress][tokenId];
        require(listedItem.isListed, "Item not listed");
        require(msg.value == listedItem.price, "Price not met"); // this protects against price manipulation

        // 1. calculate fees
        // fee for the marketplace
        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        // amount fpr the seller
        uint256 sellerAmount = msg.value - feeAmount;

        // 2. update state (delete listing BEFORE transfer to prevent reentrancy)
        delete listings[nftAddress][tokenId];
        feesCollected += feeAmount;

        // 3. transfer money (to pay the seller)
        (bool success, ) = payable(listedItem.seller).call{value: sellerAmount}("");
        require(success, "Transfer to seller failed");

        // 4. transfer NFT
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external nonReentrant {
        Listing memory listedItem = listings[nftAddress][tokenId];
        require(listedItem.seller == msg.sender, "tsk tsk you are not the seller");
        require(listedItem.isListed, "Not listed");

        delete listings[nftAddress][tokenId];
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function withdrawFees() external {
        require(msg.sender == owner, "Only owner");
        (bool success, ) = payable(feeRecipient).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // OFFERS / BIDDING
    struct Offer {
        address bidder;
        uint256 amount;
        uint256 expiration;
    }

    mapping(address => mapping(uint256 => Offer[])) public offers;

    function makeOffer(address nftAddress, uint256 tokenId) external payable {
        offers[nftAddress][tokenId].push(Offer({
            bidder: msg.sender, 
            amount: msg.value,
            expiration: block.timestamp + 7 days
        }));
    }

    function acceptOffer(address nftAddress, uint256 tokenId, uint256 offerIndex) external {
        // seller accepts a specific offer
    }

    // AUCTIONS
    struct Action {
        address seller;
        uint256 startPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
    }

    function createAuction(address nftAddress, uint256 tokenId, uint256 startPrice, uint256 duration) external {}

    // BUNDLE SALES
    struct Bundle {
        address[] nftAddresses;
        uint256[] tokenIds;
        uint256 price;
    }

    function listBundle(address[] memory nfts, uint256[] memory ids, uint256[] memory prices) external {
        for (uint i = 0; i < nfts.length; i++) {
            listItem(nfts[i], ids[i], prices[i]);
        }
    }
}