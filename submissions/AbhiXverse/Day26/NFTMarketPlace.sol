// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721, IERC2981} from "./Interfaces.sol";

contract NFTMarketplace {
    // Listing info
    struct Listing {
        address seller;
        uint256 price;
    }

    // nftContract => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // Events
    event NFTListed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, address seller, address indexed buyer, uint256 price);
    event ListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);

    // Errors
    error PriceMustBeAboveZero();
    error NotOwner();
    error NotApprovedForMarketplace();
    error AlreadyListed(address nftContract, uint256 tokenId);
    error NotListed(address nftContract, uint256 tokenId);
    error PriceNotMet(address nftContract, uint256 tokenId, uint256 requiredPrice, uint256 sentValue);
    error RoyaltyPaymentFailed();
    error SellerPaymentFailed();

    // Interface IDs
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // List NFT for sale
    function listNFT(address nftContractAddress, uint256 tokenId, uint256 price) external {
        if (price == 0) revert PriceMustBeAboveZero();
        if (listings[nftContractAddress][tokenId].seller != address(0)) revert AlreadyListed(nftContractAddress, tokenId);

        IERC721 nftContract = IERC721(nftContractAddress);
        if (nftContract.ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (nftContract.getApproved(tokenId) != address(this)) revert NotApprovedForMarketplace();

        listings[nftContractAddress][tokenId] = Listing(msg.sender, price);
        emit NFTListed(nftContractAddress, tokenId, msg.sender, price);
    }

    // Buy listed NFT
    function buyNFT(address nftContractAddress, uint256 tokenId) external payable {
        Listing memory listing = listings[nftContractAddress][tokenId];
        if (listing.seller == address(0)) revert NotListed(nftContractAddress, tokenId);
        if (msg.value != listing.price) revert PriceNotMet(nftContractAddress, tokenId, listing.price, msg.value);

        delete listings[nftContractAddress][tokenId];

        IERC721 nftContract = IERC721(nftContractAddress);
        IERC2981 royaltyContract = IERC2981(nftContractAddress);

        uint256 royaltyAmount = 0;
        address royaltyReceiver;
        uint256 sellerProceeds = listing.price;

        try royaltyContract.supportsInterface(_INTERFACE_ID_ERC2981) returns (bool isSupported) {
            if (isSupported) {
                (royaltyReceiver, royaltyAmount) = royaltyContract.royaltyInfo(tokenId, listing.price);
                if (royaltyAmount > 0 && royaltyAmount <= listing.price) {
                    sellerProceeds = listing.price - royaltyAmount;
                } else {
                    royaltyAmount = 0;
                    royaltyReceiver = address(0);
                }
            }
        } catch {
            royaltyAmount = 0;
            royaltyReceiver = address(0);
        }

        nftContract.safeTransferFrom(listing.seller, msg.sender, tokenId);

        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
            bool royaltyPaid = _safeSendValue(payable(royaltyReceiver), royaltyAmount);
            if (!royaltyPaid) revert RoyaltyPaymentFailed();
        }

        if (sellerProceeds > 0) {
            bool sellerPaid = _safeSendValue(payable(listing.seller), sellerProceeds);
            if (!sellerPaid) revert SellerPaymentFailed();
        }

        emit NFTSold(nftContractAddress, tokenId, listing.seller, msg.sender, listing.price);
    }

    // Cancel listing
    function cancelListing(address nftContractAddress, uint256 tokenId) external {
        Listing memory listing = listings[nftContractAddress][tokenId];
        if (listing.seller == address(0)) revert NotListed(nftContractAddress, tokenId);
        if (msg.sender != listing.seller) revert NotOwner();

        delete listings[nftContractAddress][tokenId];
        emit ListingCancelled(nftContractAddress, tokenId, listing.seller);
    }

    // Update listing price
    function updateListingPrice(address nftContractAddress, uint256 tokenId, uint256 newPrice) external {
        Listing storage listing = listings[nftContractAddress][tokenId];
        if (listing.seller == address(0)) revert NotListed(nftContractAddress, tokenId);
        if (msg.sender != listing.seller) revert NotOwner();
        if (newPrice == 0) revert PriceMustBeAboveZero();

        listing.price = newPrice;
    }

    // Internal ether transfer helper
    function _safeSendValue(address payable recipient, uint256 amount) internal returns (bool success) {
        if (amount == 0) return true;
        (success, ) = recipient.call{value: amount}("");
    }
}
