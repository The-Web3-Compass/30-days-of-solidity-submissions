// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title  NFTMarketplace — Misty Market 🛍️
/// @author rainwaters11 — Day 26: NFT Marketplace
/// @notice A non-custodial, multi-collection NFT marketplace.
///         Sellers list any ERC-721 NFT at a fixed ETH price.
///         Buyers purchase with a single transaction.
///         A 2.5 % (250 BPS) marketplace fee is taken on each sale.
///
/// @dev    NON-CUSTODIAL — THE APPROVAL PATTERN
///         ┌──────────────────────────────────────────────────────────────┐
///         │  Traditional pawn shop:  You GIVE them the item to sell it.  │
///         │  Misty Market:           NFT STAYS IN YOUR WALLET.           │
///         │                                                              │
///         │  1. Seller calls nftContract.approve(marketplace, tokenId)   │
///         │     → Gives permission to move the NFT on their behalf.      │
///         │  2. Seller calls listItem() — metadata stored on-chain.      │
///         │  3. Buyer calls buyItem()   — one atomic transaction:        │
///         │       a. ETH sent in by buyer.                               │
///         │       b. Contract transfers NFT from seller → buyer.         │
///         │       c. ETH (minus fee) transferred to seller.              │
///         │     Either ALL of this happens or NONE of it.                │
///         └──────────────────────────────────────────────────────────────┘
///
///         THE ATOMIC SWAP — WHY NO ESCROW IS NEEDED
///         ┌──────────────────────────────────────────────────────────────┐
///         │  In computer science, "atomic" means indivisible:            │
///         │  it either completes fully or reverts entirely.              │
///         │                                                              │
///         │  If the seller moves their NFT after listing but BEFORE      │
///         │  someone buys, the safeTransferFrom inside buyItem() will    │
///         │  revert (the marketplace is no longer approved).             │
///         │  The buyer's ETH is automatically returned — no loss.        │
///         │                                                              │
///         │  The code IS the escrow.                                     │
///         └──────────────────────────────────────────────────────────────┘
///
///         THE FEE ENGINE — BASIS POINT STANDARD
///         ┌──────────────────────────────────────────────────────────────┐
///         │  1 BPS = 0.01 %                                              │
///         │  250 BPS = 2.50 % (MARKETPLACE_FEE_BPS)                     │
///         │                                                              │
///         │  fee      = price × 250 / 10_000                            │
///         │  sellerNet = price − fee                                     │
///         │                                                              │
///         │  Example: 1 ETH sale                                         │
///         │    fee      = 1e18 × 250 / 10_000 = 0.025 ETH               │
///         │    seller   = 0.975 ETH                                      │
///         │    platform = 0.025 ETH (accumulated in feeBalance)          │
///         └──────────────────────────────────────────────────────────────┘
///
///         MULTI-COLLECTION SUPPORT — NESTED MAPPING
///         ┌──────────────────────────────────────────────────────────────┐
///         │  listings[nftContract][tokenId] = Listing                    │
///         │                                                              │
///         │  This single mapping supports ALL ERC-721 collections        │
///         │  simultaneously.  No re-deployment needed for new NFTs.      │
///         │  Misty Crochet Badges, partner PFPs, game items — all        │
///         │  trade on the same marketplace with the same fee structure.  │
///         └──────────────────────────────────────────────────────────────┘
///
///         CHECKS-EFFECTS-INTERACTIONS (C-E-I) IN buyItem
///         State changes happen BEFORE any external calls:
///           1. CHECK  — price matches, listing exists, not self-buying
///           2. EFFECT — delete listing, update feeBalance       ← FIRST
///           3. INTERACT — transferFrom NFT, transfer ETH to seller ← LAST
///         This ordering prevents reentrancy attacks without needing an
///         extra modifier on buyItem, though ReentrancyGuard is still used
///         as a belt-and-suspenders measure.
///
///         USE CASES IN MISTYCOIN-CORE
///         • Community trades MistyCoin NFTs (Day 26) peer-to-peer.
///         • Protocol earns revenue from fees → MultiSig treasury (Day 24).
///         • Pricefeed integration possible for ETH→USD display on frontend.
contract NFTMarketplace is ReentrancyGuard, Ownable {

    // ─── Constants ────────────────────────────────────────────────────────────

    /// @notice Precision divisor: 10_000 BPS = 100 %.
    uint256 public constant BPS_PRECISION = 10_000;

    /// @notice Marketplace fee = 2.5 % = 250 BPS.
    ///         Applied on every successful sale.
    ///         Fee = price × 250 / 10_000
    uint256 public constant MARKETPLACE_FEE_BPS = 250;

    // ─── Structs ──────────────────────────────────────────────────────────────

    /// @notice Represents a single NFT listed for sale.
    struct Listing {
        address seller;   // who listed it — receives ETH on sale
        uint256 price;    // asking price in wei (ETH)
    }

    // ─── State ────────────────────────────────────────────────────────────────

    /// @dev NESTED MAPPING — MULTI-COLLECTION SUPPORT
    ///      listings[nftContract][tokenId] → Listing
    ///      Supports ANY ERC-721 on any address — one contract for all NFTs.
    mapping(address => mapping(uint256 => Listing)) public listings;

    /// @notice Accumulated marketplace fees ready to be withdrawn by owner.
    uint256 public feeBalance;

    // ─── Events ───────────────────────────────────────────────────────────────

    event ItemListed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    event ItemUpdated(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 newPrice
    );

    event ItemCancelled(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller
    );

    event ItemSold(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed buyer,
        address  seller,
        uint256  price,
        uint256  fee,
        uint256  sellerProceeds
    );

    event FeesWithdrawn(address indexed owner, uint256 amount);

    // ─── Errors ───────────────────────────────────────────────────────────────

    error ZeroPrice();
    error NotApproved();               // marketplace not approved to transfer NFT
    error NotOwnerOfToken();           // caller doesn't own the NFT they're listing
    error AlreadyListed();             // tokenId already has an active listing
    error NotListed();                 // no listing found for this NFT
    error NotSeller();                 // only the original seller can cancel/update
    error InsufficientPayment();       // buyer sent less ETH than the price
    error CannotBuyOwnItem();          // seller and buyer are the same address
    error ETHTransferFailed();         // low-level ETH call to seller failed
    error NoFeesToWithdraw();

    // ─── Modifiers ────────────────────────────────────────────────────────────

    /// @dev Ensures a listing exists for the given NFT.
    modifier isListed(address nftContract, uint256 tokenId) {
        if (listings[nftContract][tokenId].price == 0) revert NotListed();
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _owner  Initial owner — receives marketplace fees.
    ///                In production this should be the Day 24 MultiSig.
    constructor(address _owner) Ownable(_owner) {}

    // ─── Core: List ───────────────────────────────────────────────────────────

    /// @notice List an ERC-721 NFT for sale at a fixed ETH price.
    ///
    /// @dev    THE APPROVAL HANDSHAKE (caller must do this first):
    ///           nftContract.approve(address(this), tokenId)
    ///           OR
    ///           nftContract.setApprovalForAll(address(this), true)
    ///
    ///         We verify the approval on-chain before accepting the listing.
    ///         If the seller unapproves later, the listing becomes stale and
    ///         buyItem() will revert — protecting the buyer automatically.
    ///
    ///         The NFT is NOT transferred here.  It stays in the seller's wallet
    ///         until the moment a buyer calls buyItem().
    ///
    /// @param nftContract  ERC-721 contract address.
    /// @param tokenId      ID of the NFT to sell.
    /// @param price        Asking price in wei.  Must be > 0.
    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external {
        if (price == 0) revert ZeroPrice();

        IERC721 nft = IERC721(nftContract);

        // CHECKS — ownership and marketplace approval
        if (nft.ownerOf(tokenId) != msg.sender)          revert NotOwnerOfToken();
        if (listings[nftContract][tokenId].price != 0)   revert AlreadyListed();

        // Verify marketplace has permission to move this NFT on buyer's trigger.
        address approved = nft.getApproved(tokenId);
        bool    approvedForAll = nft.isApprovedForAll(msg.sender, address(this));
        if (approved != address(this) && !approvedForAll) revert NotApproved();

        // EFFECTS
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price:  price
        });

        emit ItemListed(nftContract, tokenId, msg.sender, price);
    }

    // ─── Core: Update price ───────────────────────────────────────────────────

    /// @notice Change the asking price of an existing listing.
    ///
    /// @param nftContract  ERC-721 contract address.
    /// @param tokenId      ID of the listed NFT.
    /// @param newPrice     New asking price in wei.  Must be > 0.
    function updateListing(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external isListed(nftContract, tokenId) {
        if (newPrice == 0) revert ZeroPrice();

        Listing storage listing = listings[nftContract][tokenId];
        if (listing.seller != msg.sender) revert NotSeller();

        listing.price = newPrice;

        emit ItemUpdated(nftContract, tokenId, msg.sender, newPrice);
    }

    // ─── Core: Cancel ─────────────────────────────────────────────────────────

    /// @notice Cancel your listing and remove it from the marketplace.
    ///         Only the original seller can cancel.
    ///
    /// @param nftContract  ERC-721 contract address.
    /// @param tokenId      ID of the listed NFT.
    function cancelListing(address nftContract, uint256 tokenId)
        external
        isListed(nftContract, tokenId)
    {
        Listing storage listing = listings[nftContract][tokenId];
        if (listing.seller != msg.sender) revert NotSeller();

        // EFFECTS — delete before any event emission
        delete listings[nftContract][tokenId];

        emit ItemCancelled(nftContract, tokenId, msg.sender);
    }

    // ─── Core: Buy ────────────────────────────────────────────────────────────

    /// @notice Purchase a listed NFT.  Send exact ETH as msg.value.
    ///
    /// @dev    STRICT CHECKS-EFFECTS-INTERACTIONS ORDER — THE KEY SAFETY RULE
    ///
    ///         ✅ CHECKS  (validate all pre-conditions)
    ///           • listing exists (isListed modifier)
    ///           • buyer is not the seller
    ///           • msg.value >= price
    ///
    ///         ✅ EFFECTS  (update ALL state before any external calls)
    ///           • delete listings[nftContract][tokenId]  ← CRITICAL FIRST
    ///             Deleting the listing BEFORE the transfer prevents a
    ///             malicious seller/NFT contract from re-entering buyItem
    ///             and selling the same NFT twice.
    ///           • feeBalance += fee
    ///
    ///         ✅ INTERACTIONS  (external calls last)
    ///           • safeTransferFrom(seller → buyer)  ← ERC-721 transfer
    ///           • seller.call{value: sellerNet}()   ← ETH payment to seller
    ///
    ///         OVERPAYMENT: If the buyer sends more ETH than the price,
    ///         the excess is NOT refunded here (keep it simple).  UI should
    ///         send exact amounts.  A production system would refund excess.
    ///
    /// @param nftContract  ERC-721 contract address.
    /// @param tokenId      Token ID to purchase.
    function buyItem(address nftContract, uint256 tokenId)
        external
        payable
        nonReentrant
        isListed(nftContract, tokenId)
    {
        Listing memory listing = listings[nftContract][tokenId];

        // ── CHECKS ────────────────────────────────────────────────────────────
        if (msg.sender == listing.seller)    revert CannotBuyOwnItem();
        if (msg.value < listing.price)       revert InsufficientPayment();

        // ── EFFECTS — state changes BEFORE any external calls ─────────────────

        // 1. DELETE the listing FIRST — prevents reentrancy from re-selling.
        //    After this line, any recursive call back into buyItem will hit
        //    NotListed() and revert.
        delete listings[nftContract][tokenId];

        // 2. Calculate fee and seller proceeds.
        uint256 fee         = (listing.price * MARKETPLACE_FEE_BPS) / BPS_PRECISION;
        uint256 sellerNet   = listing.price - fee;

        // 3. Accumulate fee in contract — owner withdraws separately.
        feeBalance += fee;

        // ── INTERACTIONS — external calls LAST ───────────────────────────────

        // Transfer NFT from seller's wallet to buyer atomically.
        // If seller revoked approval or transferred the NFT, this reverts
        // and the buyer's ETH is returned automatically (atomic guarantee).
        IERC721(nftContract).safeTransferFrom(listing.seller, msg.sender, tokenId);

        // Pay the seller their net proceeds (price minus marketplace fee).
        (bool success, ) = payable(listing.seller).call{value: sellerNet}("");
        if (!success) revert ETHTransferFailed();

        emit ItemSold(
            nftContract,
            tokenId,
            msg.sender,
            listing.seller,
            listing.price,
            fee,
            sellerNet
        );
    }

    // ─── Admin: Fee Withdrawal ────────────────────────────────────────────────

    /// @notice Withdraw accumulated marketplace fees to the owner address.
    ///
    /// @dev    In production, point `owner` to the Day 24 MultiSig wallet
    ///         so fee withdrawals also require M-of-N confirmation.
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 amount = feeBalance;
        if (amount == 0) revert NoFeesToWithdraw();

        // EFFECTS before INTERACTIONS
        feeBalance = 0;

        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) revert ETHTransferFailed();

        emit FeesWithdrawn(owner(), amount);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Returns an active listing, or a zero-price Listing if not found.
    ///
    /// @param nftContract  ERC-721 contract to query.
    /// @param tokenId      Token ID to look up.
    /// @return             The Listing struct (seller + price). Price == 0 if not listed.
    function getListing(address nftContract, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[nftContract][tokenId];
    }

    /// @notice Calculate the fee and seller net for a given sale price.
    ///         Useful for UI preview before the buyer calls buyItem().
    ///
    /// @param price  Sale price in wei.
    /// @return fee         Marketplace fee (2.5 %).
    /// @return sellerNet   Amount the seller would receive.
    function calculateFee(uint256 price)
        external
        pure
        returns (uint256 fee, uint256 sellerNet)
    {
        fee       = (price * MARKETPLACE_FEE_BPS) / BPS_PRECISION;
        sellerNet = price - fee;
    }

    /// @notice Check whether a specific NFT is currently listed.
    function isItemListed(address nftContract, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return listings[nftContract][tokenId].price > 0;
    }

    // ─── Receive ETH ──────────────────────────────────────────────────────────

    /// @dev Accept plain ETH (e.g. from accidental sends).
    ///      In production you may want to revert here instead.
    receive() external payable {}
}
