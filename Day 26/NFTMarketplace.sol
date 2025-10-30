// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTMarketplace
 * @author @the_web3compass builder 
 * @notice A decentralized marketplace for buying and selling ERC721 NFTs with royalty support.
 * @dev Demonstrates marketplace logic, payments, and security best practices.
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    using Address for address payable;

    // --- STRUCTS ---

    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool sold;
    }

    struct RoyaltyInfo {
        address payable creator;
        uint96 royaltyFraction; // e.g. 500 = 5%
    }

    // --- STATE VARIABLES ---

    Counters.Counter private _listingIds;
    Counters.Counter private _itemsSold;

    mapping(uint256 => Listing) public listings;
    mapping(address => mapping(uint256 => RoyaltyInfo)) public royalties; // nftContract => tokenId => RoyaltyInfo

    uint256 public listingFee = 0.002 ether;
    address payable public owner;

    // --- EVENTS ---
    event Listed(uint256 indexed listingId, address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price);
    event Sale(uint256 indexed listingId, address buyer, uint256 price);
    event Canceled(uint256 indexed listingId);
    event RoyaltySet(address indexed nftContract, uint256 indexed tokenId, address indexed creator, uint96 royaltyFraction);
    event ListingFeeUpdated(uint256 newFee);

    // --- MODIFIERS ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not marketplace owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // --- CORE LOGIC ---

    /**
     * @notice List an NFT for sale.
     * @param nftContract The address of the ERC721 NFT.
     * @param tokenId The NFT ID to list.
     * @param price The sale price in wei.
     */
    function listNFT(address nftContract, uint256 tokenId, uint256 price)
        external
        payable
        nonReentrant
    {
        require(price > 0, "Price must be > 0");
        require(msg.value == listingFee, "Pay exact listing fee");

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        listings[listingId] = Listing({
            listingId: listingId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: payable(msg.sender),
            price: price,
            sold: false
        });

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit Listed(listingId, nftContract, tokenId, msg.sender, price);
    }

    /**
     * @notice Buy a listed NFT.
     * @param listingId The ID of the NFT listing.
     */
    function buyNFT(uint256 listingId)
        external
        payable
        nonReentrant
    {
        Listing storage listing = listings[listingId];
        require(!listing.sold, "Already sold");
        require(msg.value >= listing.price, "Insufficient payment");

        listing.sold = true;
        _itemsSold.increment();

        RoyaltyInfo memory royalty = royalties[listing.nftContract][listing.tokenId];
        uint256 royaltyAmount = (msg.value * royalty.royaltyFraction) / 10000;
        uint256 sellerProceeds = msg.value - royaltyAmount;

        if (royalty.creator != address(0) && royaltyAmount > 0) {
            royalty.creator.sendValue(royaltyAmount);
        }

        listing.seller.sendValue(sellerProceeds);

        IERC721(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);

        emit Sale(listingId, msg.sender, listing.price);
    }

    /**
     * @notice Cancel a listing and return the NFT to the seller.
     * @param listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Not your listing");
        require(!listing.sold, "Already sold");

        IERC721(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);
        delete listings[listingId];

        emit Canceled(listingId);
    }

    // --- ROYALTY LOGIC ---

    /**
     * @notice Set royalty info for an NFT.
     * @param nftContract The NFT contract address.
     * @param tokenId The NFT token ID.
     * @param creator The original creator address.
     * @param royaltyFraction The royalty percentage (100 = 1%, 1000 = 10%).
     */
    function setRoyalty(
        address nftContract,
        uint256 tokenId,
        address payable creator,
        uint96 royaltyFraction
    ) external {
        require(royaltyFraction <= 1000, "Max 10%");
        require(creator != address(0), "Invalid creator");

        royalties[nftContract][tokenId] = RoyaltyInfo(creator, royaltyFraction);

        emit RoyaltySet(nftContract, tokenId, creator, royaltyFraction);
    }

    // --- ADMIN / VIEW FUNCTIONS ---

    function getListing(uint256 listingId)
        external
        view
        returns (Listing memory)
    {
        return listings[listingId];
    }

    function getUnsoldItemsCount() external view returns (uint256) {
        return _listingIds.current() - _itemsSold.current();
    }

    function updateListingFee(uint256 newFee) external onlyOwner {
        listingFee = newFee;
        emit ListingFeeUpdated(newFee);
    }

    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        owner.sendValue(balance);
    }

    receive() external payable {}
}
