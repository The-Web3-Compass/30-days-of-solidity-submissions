// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721, IERC2981} from "./Interfaces.sol";

/**
 * @title NFTMarketplace
 * @author shivam
 * @notice A simple marketplace for buying and selling ERC721 NFTs, supporting ERC2981 royalties.
 */
contract NFTMarketplace {
    // --- Structs ---
    /**
     * @notice Represents an active listing on the marketplace.
     * @param seller The address of the user who listed the NFT.
     * @param price The price of the NFT in wei.
     */
    struct Listing {
        address seller;
        uint256 price;
    }

    // --- State Variables ---

    /**
     * @notice Mapping from NFT contract address to token ID to the listing details.
     * @dev Used to store and retrieve active listings. Access: listings[nftContractAddress][tokenId]
     */
    mapping(address => mapping(uint256 => Listing)) public listings;

    // --- Events ---
    /**
     * @notice Emitted when an NFT is successfully listed for sale.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the listed NFT.
     * @param seller The address of the seller.
     * @param price The listing price in wei.
     */
    event NFTListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    /**
     * @notice Emitted when an NFT is successfully bought and transferred.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the sold NFT.
     * @param seller The address of the seller (previous owner).
     * @param buyer The address of the buyer (new owner).
     * @param price The price the NFT was sold for in wei.
     */
    event NFTSold(
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address indexed buyer,
        uint256 price
    );

    /**
     * @notice Emitted when a listing is cancelled by the seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT whose listing was cancelled.
     * @param seller The address of the seller who cancelled the listing.
     */
    event ListingCancelled(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller
    );

    // --- Errors ---
    /// @notice Error thrown when attempting to list an NFT with a price of zero.
    error PriceMustBeAboveZero();

    /// @notice Error thrown when an action is attempted by an address that is not the owner or seller.
    error NotOwner();
    
    /// @notice Error thrown when trying to list an NFT for which the marketplace contract is not approved.
    error NotApprovedForMarketplace();

    /**
     * @notice Error thrown when trying to list an NFT that is already listed.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the already listed NFT.
     */
    error AlreadyListed(address nftContract, uint256 tokenId);
    
    /**
     * @notice Error thrown when trying to interact with a listing that does not exist.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT that is not listed.
     */
    error NotListed(address nftContract, uint256 tokenId);
    
    /**
     * @notice Error thrown when the Ether sent to buy an NFT does not match the listing price.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being purchased.
     * @param requiredPrice The listed price of the NFT.
     * @param sentValue The amount of Ether sent with the transaction.
     */
    error PriceNotMet(
        address nftContract,
        uint256 tokenId,
        uint256 requiredPrice,
        uint256 sentValue
    );
    
    /// @notice Error thrown if the royalty payment fails during a purchase.
    error RoyaltyPaymentFailed();
    
    /// @notice Error thrown if the payment to the seller fails during a purchase.
    error SellerPaymentFailed();

    // --- Constants ---
    /** @notice ERC721 interface ID. */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    /** @notice ERC2981 Royalty Standard interface ID. */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // --- Functions ---

    /**
     * @notice Lists an NFT for sale on the marketplace.
     * @dev Caller must be the owner of the NFT and must have approved the marketplace
     *      contract to transfer the NFT beforehand.
     * @param nftContractAddress The address of the ERC721 NFT contract.
     * @param tokenId The ID of the NFT to list.
     * @param price The selling price in wei (must be > 0).
     */
    function listNFT(address nftContractAddress, uint256 tokenId, uint256 price) external {
        if (price == 0) {
            revert PriceMustBeAboveZero();
        }
        if (listings[nftContractAddress][tokenId].seller != address(0)) {
            revert AlreadyListed(nftContractAddress, tokenId);
        }

        IERC721 nftContract = IERC721(nftContractAddress);
        if (nftContract.ownerOf(tokenId) != msg.sender) {
            revert NotOwner();
        }
        // Check if this contract is approved for the specific token ID.
        // Note: We don't need to check isApprovedForAll, as getApproved covers the necessary permission.
        if (nftContract.getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }

        listings[nftContractAddress][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });

        emit NFTListed(nftContractAddress, tokenId, msg.sender, price);
    }
    /**
     * @notice Buys a listed NFT.
     * @dev Sends the listing price amount from the buyer to the seller, potentially deducting and sending royalties if the NFT supports ERC2981.
     * @param nftContractAddress The address of the ERC721 NFT contract.
     * @param tokenId The ID of the NFT to buy.
     */
    function buyNFT(address nftContractAddress, uint256 tokenId) external payable {
        Listing memory listing = listings[nftContractAddress][tokenId];
        address seller = listing.seller;
        uint256 price = listing.price;

        if (seller == address(0)) {
            revert NotListed(nftContractAddress, tokenId);
        }
        if (msg.value != price) {
            revert PriceNotMet(nftContractAddress, tokenId, price, msg.value);
        }

        // Remove listing before external calls to prevent reentrancy
        delete listings[nftContractAddress][tokenId];

        IERC721 nftContract = IERC721(nftContractAddress);
        IERC2981 royaltyContract = IERC2981(nftContractAddress);

        uint256 royaltyAmount = 0;
        address royaltyReceiver;
        uint256 sellerProceeds = price;

        // Check for ERC2981 support and calculate royalties
        try royaltyContract.supportsInterface(_INTERFACE_ID_ERC2981) returns (
            bool isSupported
        ) {
            if (isSupported) {
                (royaltyReceiver, royaltyAmount) = royaltyContract.royaltyInfo(tokenId, price);
                // Basic sanity check on royalty amount
                if (royaltyAmount > 0 && royaltyAmount <= price) {
                    // Only deduct if royalty is valid and non-zero
                    sellerProceeds = price - royaltyAmount;
                } else {
                    // If royalty amount is invalid (e.g., > price or 0 when receiver is set),
                    // ignore it and give full proceeds to seller. Reset receiver.
                    royaltyAmount = 0;
                    royaltyReceiver = address(0);
                }
            }
            // If interface not supported, royaltyAmount remains 0, sellerProceeds remains price.
        } catch {
            // If supportsInterface or royaltyInfo reverts, treat as no royalty support.
            royaltyAmount = 0;
            royaltyReceiver = address(0);
            // sellerProceeds already equals price
        }

        // Transfer NFT (reverts internally on failure typically)
        // We assume safeTransferFrom handles checks like ownership changes since listing.
        // If it fails, the state change (listing deletion) is already done, but money hasn't moved.
        // The buyer keeps their ETH, seller keeps NFT, listing is gone (buyer needs to relist).
        // This is acceptable, avoids reentrancy lock.
        nftContract.safeTransferFrom(seller, msg.sender, tokenId);

        // Pay Royalty if applicable
        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
            bool royaltyPaid = _safeSendValue(
                payable(royaltyReceiver),
                royaltyAmount
            );
            if (!royaltyPaid) {
                // Note: If royalty payment fails, the transaction reverts,
                revert RoyaltyPaymentFailed();
            }
        }

        // Pay Seller
        if (sellerProceeds > 0) {
            bool sellerPaid = _safeSendValue(payable(seller), sellerProceeds);
            if (!sellerPaid) {
                // Note: If seller payment fails, the transaction reverts.
                revert SellerPaymentFailed();
            }
        }

        emit NFTSold(nftContractAddress, tokenId, seller, msg.sender, price);
    }

    /**
     * @notice Allows the seller to cancel their NFT listing.
     * @dev Caller must be the seller of the listed NFT.
     * @param nftContractAddress The address of the ERC721 NFT contract.
     * @param tokenId The ID of the NFT whose listing is to be cancelled.
     */
    function cancelListing(
        address nftContractAddress,
        uint256 tokenId
    ) external {
        Listing memory listing = listings[nftContractAddress][tokenId];
        address seller = listing.seller;

        if (seller == address(0)) {
            revert NotListed(nftContractAddress, tokenId);
        }
        if (msg.sender != seller) {
            revert NotOwner();
        }

        delete listings[nftContractAddress][tokenId];

        emit ListingCancelled(nftContractAddress, tokenId, seller);
    }

    /**
     * @notice Allows the seller to update the price of their listed NFT.
     * @dev Caller must be the seller of the listed NFT.
     * @param nftContractAddress The address of the ERC721 NFT contract.
     * @param tokenId The ID of the NFT whose listing price is to be updated.
     * @param newPrice The new selling price in wei (must be > 0).
     */
    function updateListingPrice(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external {
        // Use storage pointer for direct update
        Listing storage listing = listings[nftContractAddress][tokenId];
        address seller = listing.seller;

        if (seller == address(0)) {
            revert NotListed(nftContractAddress, tokenId);
        }
        if (msg.sender != seller) {
            revert NotOwner();
        }
        if (newPrice == 0) {
            revert PriceMustBeAboveZero();
        }

        listing.price = newPrice;
    }

    /**
     * @notice Internal helper to safely send Ether using low-level call.
     * @dev Reduces contract size compared to importing SafeERC20 or Address.
     * @param recipient The address to send Ether to.
     * @param amount The amount of Ether (in wei) to send.
     * @return success Boolean indicating if the transfer succeeded.
     */
    function _safeSendValue(
        address payable recipient,
        uint256 amount
    ) internal returns (bool success) {
        if (amount == 0) {
            return true; // Nothing to send
        }
        (success, ) = recipient.call{value: amount}("");
        // don't revert here directly, the caller should check 'success' and revert with a specific error.
    }
}
