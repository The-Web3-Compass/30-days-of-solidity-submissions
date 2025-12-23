// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title AutomatedMarketMaker
 * @dev Build a system for trading tokens automatically.
 * You'll learn how to create liquidity pools and implement the constant product formula, demonstrating AMM logic.
 * It's like a digital exchange for tokens, showing how to create automated markets.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 25
 */
contract NftMarketplace is Ownable, ReentrancyGuard {
    enum ListingState {
        UNLISTED,
        LISTED,
        SOLD,
        CANCELLED
    }
    struct Listing {
        ListingState state;
        IERC721 nft;
        uint256 nftId;
        uint256 price;
        address payable royaltyOwner;
        uint256 royaltyPercent;
        address payable seller;
        address payable buyer;
    }

    uint256 public tradeFee = 300; // 300 basis points = 3%
    uint256 public defaultRoyaltyPercent = 200;  // 200 basis points = 2%
    address payable tradeFeeOwner;
    address payable defaultRoyaltyOwner;
    mapping(IERC721 => mapping(uint256 => Listing)) listings; // nft => nftId => listing

    constructor() Ownable(msg.sender) ReentrancyGuard() {
        tradeFeeOwner = payable(owner());
        defaultRoyaltyOwner = tradeFeeOwner;
    }

    function setTradeFee(uint256 newFeeBasisPoints, address payable newTradeFeeOwner) public onlyOwner {
        require(newTradeFeeOwner != address(0x00) && newTradeFeeOwner != address(this), "null or self addresses not allowed");
        require(newFeeBasisPoints < 10_000, "trading fee must be less than 100%");
        tradeFee = newFeeBasisPoints;
        tradeFeeOwner = newTradeFeeOwner;
    }

    function addListing(
        IERC721 nft,
        uint256 nftId,
        uint256 price,
        address payable royaltyOwner,
        uint256 royaltyPercent
    ) public {
        require(price > 0, "price must be more than zero");
        require(listings[nft][nftId].state != ListingState.LISTED, "already listed");
        require(
            (nft.ownerOf(nftId) == msg.sender) &&
            (nft.getApproved(nftId) == address(this) || nft.isApprovedForAll(msg.sender, address(this))),
            "can not list without owning nft and approving marketplace"
        );
        listings[nft][nftId] = Listing({
            state: ListingState.LISTED,
            nft: nft,
            nftId: nftId,
            price: price,
            royaltyOwner: (royaltyOwner != address(0x00) ? royaltyOwner : defaultRoyaltyOwner ),
            royaltyPercent: (royaltyPercent > 0 ? royaltyPercent : defaultRoyaltyPercent),
            seller: payable(msg.sender),
            buyer: payable(address(0x00))
        });
    }

    function buyListing(
        IERC721 nft,
        uint256 nftId
    ) public payable nonReentrant {
        Listing memory listing = listings[nft][nftId];
        require(listing.state == ListingState.LISTED, "nft is not listed for sale");
        require(msg.value == listing.price, "must pay listing price");
        require(tradeFee + listing.royaltyPercent < 10_000, "total fees must be less than 100%");

        uint256 listingTradeFee = listing.price * tradeFee / 10_000;
        uint256 listingRoyalty = listing.price * listing.royaltyPercent / 10_000;
        uint256 listingSeller = listing.price - listingTradeFee - listingRoyalty;

        if (listingTradeFee > 0) {
            (bool transferSuccess1,) = tradeFeeOwner.call{ value: listingTradeFee }("");
            require(transferSuccess1, "transfer of trade fee failed");
        }

        if (listingRoyalty > 0) {
            (bool transferSuccess2,) = listing.royaltyOwner.call{ value: listingRoyalty }("");
            require(transferSuccess2, "transfer of royalty failed");
        }

        (bool transferSuccess3,) = listing.seller.call{ value: listingSeller }("");
        require(transferSuccess3, "transfer to seller failed");

        nft.safeTransferFrom(listing.seller, msg.sender, nftId);

        listing.state = ListingState.SOLD;
        listing.buyer = payable(msg.sender);
        listings[nft][nftId] = listing;
    }

    function cancelListing(
        IERC721 nft,
        uint256 nftId
    ) public payable {
        Listing memory listing = listings[nft][nftId];
        require(listing.state == ListingState.LISTED, "nft is not listed for sale");
        require((nft.ownerOf(nftId) == msg.sender), "only of nft can cancel listing");
        listings[nft][nftId].state = ListingState.CANCELLED;
    }
}
