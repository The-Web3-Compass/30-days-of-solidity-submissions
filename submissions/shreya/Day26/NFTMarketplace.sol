// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 This contract is a simple implementation of an NFT marketplace.
 */
contract NFTMarketplace is ReentrancyGuard {
    // State Variables 

    address public immutable owner;
    uint256 public marketplaceFeePercent; // in basis points (100 = 1%)
    address public feeRecipient;

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver;
        uint256 royaltyPercent; // in basis points
        bool isListed;
    }

    // A nested mapping from NFT contract address to token ID to the listing details.
    mapping(address => mapping(uint256 => Listing)) public listings;

    //Events 

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

    // Constructor 

    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Marketplace fee cannot exceed 10%");
        require(_feeRecipient != address(0), "Fee recipient cannot be the zero address");

        owner = msg.sender;
        marketplaceFeePercent = _marketplaceFeePercent;
        feeRecipient = _feeRecipient;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Owner Functions 

    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Marketplace fee cannot exceed 10%");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Fee recipient cannot be the zero address");
        feeRecipient = _newRecipient;
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);
    }

    // Core Functions 

    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    ) external {
        require(price > 0, "Price must be greater than zero");
        require(royaltyPercent <= 1000, "Royalty fee cannot exceed 10%");
        require(!listings[nftAddress][tokenId].isListed, "This NFT is already listed");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "The marketplace is not approved to transfer this NFT"
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

    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "This NFT is not listed for sale");
        require(msg.value == item.price, "Incorrect amount of ETH sent");

        uint256 totalFees = item.royaltyPercent + marketplaceFeePercent;
        require(totalFees <= 10000, "Combined fees cannot exceed 100%");

        // Calculate amounts
        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

        // Pay marketplace fee
        if (feeAmount > 0) {
            (bool success, ) = payable(feeRecipient).call{value: feeAmount}("");
            require(success, "Failed to send marketplace fee");
        }

        // Pay creator royalty
        if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
            (bool success, ) = payable(item.royaltyReceiver).call{value: royaltyAmount}("");
            require(success, "Failed to send royalty");
        }

        // Pay the seller
        (bool success, ) = payable(item.seller).call{value: sellerAmount}("");
        require(success, "Failed to pay seller");

        // Remove the listing from the marketplace
        delete listings[nftAddress][tokenId];

        // Transfer the NFT to the buyer
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

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
        require(item.isListed, "This NFT is not listed");
        require(item.seller == msg.sender, "You are not the seller of this NFT");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    // View Functions

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

    // Fallback Functions 

    receive() external payable {
        revert("Direct ETH transfers are not accepted");
    }

    fallback() external payable {
        revert("The function you are trying to call does not exist");
    }
}