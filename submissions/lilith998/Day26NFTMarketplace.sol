// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721Holder, Ownable {

    constructor() Ownable(msg.sender) {}

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver;
        uint256 royaltyFee; // expressed in basis points (e.g., 250 = 2.5%)
    }

    uint256 private _listingId;
    mapping(uint256 => Listing) public listings;

    event Listed(uint256 listingId, address seller, address nftAddress, uint256 tokenId, uint256 price);
    event Purchased(uint256 listingId, address buyer);
    event Cancelled(uint256 listingId);

    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyFee
    ) external {
        require(price > 0, "Price must be greater than zero");
        require(royaltyFee <= 1000, "Royalty too high (max 10%)");

        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        listings[_listingId] = Listing({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            royaltyReceiver: royaltyReceiver,
            royaltyFee: royaltyFee
        });

        emit Listed(_listingId, msg.sender, nftAddress, tokenId, price);
        _listingId++;
    }

    function buyNFT(uint256 listingId) external payable {
        Listing memory item = listings[listingId];
        require(item.price > 0, "Listing does not exist");
        require(msg.value >= item.price, "Insufficient payment");

        uint256 royaltyAmount = (item.price * item.royaltyFee) / 10000;
        uint256 sellerAmount = item.price - royaltyAmount;

        if (royaltyAmount > 0) {
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }
        payable(item.seller).transfer(sellerAmount);

        IERC721(item.nftAddress).safeTransferFrom(address(this), msg.sender, item.tokenId);

        delete listings[listingId];
        emit Purchased(listingId, msg.sender);
    }

    function cancelListing(uint256 listingId) external {
        Listing memory item = listings[listingId];
        require(item.seller == msg.sender, "Only seller can cancel");

        IERC721(item.nftAddress).safeTransferFrom(address(this), msg.sender, item.tokenId);
        delete listings[listingId];

        emit Cancelled(listingId);
    }

    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }
    }

