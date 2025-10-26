// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/utils/Address.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/common/ERC2981.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    using Address for address payable;

    struct Listing {
        address seller;
        uint256 price; // in wei
    }

    // marketplace fee in basis points (bps). e.g., 250 = 2.5%
    uint96 public marketplaceFeeBps;
    uint96 public constant FEE_DENOMINATOR = 10000;

    // token contract -> tokenId -> Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);
    event Cancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event Bought(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint256 price, address seller);

    constructor(uint96 _marketplaceFeeBps) {
        require(_marketplaceFeeBps <= FEE_DENOMINATOR, "fee too high");
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    // update fee
    function setMarketplaceFeeBps(uint96 _marketplaceFeeBps) external onlyOwner {
        require(_marketplaceFeeBps <= FEE_DENOMINATOR, "fee too high");
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    // List token - seller must approve this contract for the token
    function list(address nftContract, uint256 tokenId, uint256 price) external nonReentrant {
        require(price > 0, "price must be > 0");
        IERC721 token = IERC721(nftContract);
        require(token.ownerOf(tokenId) == msg.sender, "not token owner");
        require(token.getApproved(tokenId) == address(this) || token.isApprovedForAll(msg.sender, address(this)), "marketplace not approved");
        listings[nftContract][tokenId] = Listing({seller: msg.sender, price: price});
        emit Listed(nftContract, tokenId, msg.sender, price);
    }

    // Cancel listing
    function cancel(address nftContract, uint256 tokenId) external nonReentrant {
        Listing memory l = listings[nftContract][tokenId];
        require(l.seller != address(0), "not listed");
        require(l.seller == msg.sender, "not seller");
        delete listings[nftContract][tokenId];
        emit Cancelled(nftContract, tokenId, msg.sender);
    }

    // Buy listing by sending exact ETH = price
    function buy(address nftContract, uint256 tokenId) external payable nonReentrant {
        Listing memory l = listings[nftContract][tokenId];
        require(l.seller != address(0), "not listed");
        require(msg.value == l.price, "incorrect value");

        // remove listing first (checks-effects-interactions)
        delete listings[nftContract][tokenId];

        // compute marketplace fee
        uint256 feeAmount = (msg.value * marketplaceFeeBps) / FEE_DENOMINATOR;
        uint256 remaining = msg.value - feeAmount;

        // royalties?
        (address royaltyRecipient, uint256 royaltyAmount) = _getRoyaltyInfo(nftContract, tokenId, msg.value);
        if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
            // ensure we don't exceed remaining (shouldn't unless royalty + fee > price)
            if (royaltyAmount > remaining) {
                royaltyAmount = remaining;
            }
            remaining = remaining - royaltyAmount;
            // pay royalty
            payable(royaltyRecipient).sendValue(royaltyAmount);
        }

        // pay seller
        payable(l.seller).sendValue(remaining);

        // pay marketplace fee to owner
        if (feeAmount > 0) {
            payable(owner()).sendValue(feeAmount);
        }

        // transfer token
        IERC721(nftContract).safeTransferFrom(l.seller, msg.sender, tokenId);

        emit Bought(nftContract, tokenId, msg.sender, msg.value, l.seller);
    }

    // helper to get royalty info if supported
    function _getRoyaltyInfo(address nftContract, uint256 tokenId, uint256 salePrice) internal view returns (address, uint256) {
        try ERC2981(nftContract).royaltyInfo(tokenId, salePrice) returns (address receiver, uint256 amount) {
            return (receiver, amount);
        } catch {
            return (address(0), 0);
        }
    }

    // emergency withdraw if someone accidentally sent ETH to contract (owner only)
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "insufficient balance");
        to.sendValue(amount);
    }

    // Receive fallback
    receive() external payable {}
}
