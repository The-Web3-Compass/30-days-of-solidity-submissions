//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title NFT market
 * @author Eric (https://github.com/0xxEric)
 * @notice A decentralized NFT marketplace with royalties and multi-ERC20 payments.
 * @custom:project 30-days-of-solidity-submissions: Day26
 */

import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract NFTMarket is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    struct Listing {
        address seller;
        uint256 price; // in wei for ETH, or token units for ERC20
        bool active;
        address paymentToken; // address(0) for ETH, otherwise ERC20 token address
    }

    // nftContract => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // platform fees
    uint96 public platformFeeBps; // e.g., 250 = 2.5%
    uint256 public listingFeeWei;  // fixed fee paid on listing (ETH)
    address payable public feeRecipient;

    // accepted ERC20 tokens (white list). ETH is implicit (address(0))
    mapping(address => bool) public allowedPaymentTokens;

    event ItemListed(address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price, address paymentToken);
    event ListingCancelled(address indexed nftContract, uint256 indexed tokenId, address seller);
    event ItemSold(address indexed nftContract, uint256 indexed tokenId, address buyer, address seller, uint256 price, address paymentToken);
    event FeesWithdrawn(address to, uint256 amount);
    event PlatformFeeUpdated(uint96 newBps);
    event ListingFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);
    event PaymentTokenAllowed(address token, bool allowed);

    constructor(address payable _feeRecipient, uint96 _platformFeeBps, uint256 _listingFeeWei) {
        feeRecipient = _feeRecipient;
        platformFeeBps = _platformFeeBps;
        listingFeeWei = _listingFeeWei;
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Admin: allow or disallow an ERC20 token for payments
    function setPaymentTokenAllowed(address token, bool allowed) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), "Use address(0) for ETH");
        allowedPaymentTokens[token] = allowed;
        emit PaymentTokenAllowed(token, allowed);
    }

    /// @notice List an NFT for sale. Seller must be owner and must have approved marketplace.
    /// @param nftContract the NFT contract address
    /// @param tokenId nft id
    /// @param price price in wei for ETH or token decimals for ERC20
    /// @param paymentToken address(0) for ETH or ERC20 token address that must be allowed
    function listItem(address nftContract, uint256 tokenId, uint256 price, address paymentToken) external payable {
        require(price > 0, "Price > 0");

        // check listing fee for ETH only (we accept listing fee as ETH)
        require(msg.value >= listingFeeWei, "Listing fee required");

        // if ERC20 used as payment, require it's allowed
        if (paymentToken != address(0)) {
            require(allowedPaymentTokens[paymentToken], "Payment token not allowed");
        }

        IERC721 nft = IERC721(nftContract);
        address ownerOfToken = nft.ownerOf(tokenId);
        require(ownerOfToken == msg.sender, "Not token owner");

        // store listing
        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true,
            paymentToken: paymentToken
        });

        // listing fee is retained in contract (pull pattern) to avoid external call failures
        // If msg.value > listingFeeWei, refund extra immediately
        if (msg.value > listingFeeWei) {
            uint256 refund = msg.value - listingFeeWei;
            (bool refunded,) = payable(msg.sender).call{value: refund}("");
            require(refunded, "Refund failed");
        }

        emit ItemListed(nftContract, tokenId, msg.sender, price, paymentToken);
    }

    /// @notice Cancel listing
    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing storage l = listings[nftContract][tokenId];
        require(l.active, "Not listed");
        require(l.seller == msg.sender, "Not seller");
        l.active = false;
        emit ListingCancelled(nftContract, tokenId, msg.sender);
    }

    /// @notice Buy item. For ETH payments pass paymentToken = address(0) and send ETH.
    /// For ERC20 payments pass paymentToken token address and ensure buyer has approved marketplace.
    function buyItem(address nftContract, uint256 tokenId, address paymentToken) external payable nonReentrant {
        Listing storage l = listings[nftContract][tokenId];
        require(l.active, "Item not listed");

        // cache values (reduce SLOAD)
        uint256 salePrice = l.price;
        address seller = l.seller;
        address expectedPaymentToken = l.paymentToken;

        require(expectedPaymentToken == paymentToken, "Payment token mismatch");

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == seller, "Seller no longer owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(seller, address(this)),
                "Marketplace not approved");

        // compute platform fee
        uint256 platformFee = (salePrice * platformFeeBps) / 10000;

        // compute royalty if supported (try-catch safe)
        uint256 royaltyAmount = 0;
        address royaltyRecipient;
        try ERC2981(nftContract).royaltyInfo(tokenId, salePrice) returns (address rcpt, uint256 amount) {
            royaltyRecipient = rcpt;
            royaltyAmount = amount;
        } catch {
            royaltyAmount = 0;
            royaltyRecipient = address(0);
        }

        // calculate toSeller
        uint256 toSeller;
        unchecked {
            // safe because we check below that platformFee+royalty <= salePrice in effect
            if (platformFee + royaltyAmount > salePrice) {
                toSeller = 0;
            } else {
                toSeller = salePrice - platformFee - royaltyAmount;
            }
        }

        // mark listing inactive BEFORE external actions to avoid reentrancy issues
        l.active = false;

        // Transfer NFT to buyer (this will call onERC721Received on receiver if it's contract)
        nft.safeTransferFrom(seller, msg.sender, tokenId);

        // Now handle payments: ETH or ERC20
        if (paymentToken == address(0)) {
            // ETH path: buyer should have sent ETH equal to salePrice
            require(msg.value >= salePrice, "Insufficient payment");

            // platform fee -> feeRecipient (if set)
            if (platformFee > 0 && feeRecipient != address(0)) {
                (bool pf,) = feeRecipient.call{value: platformFee}("");
                require(pf, "Platform fee transfer failed");
            }

            // royalty
            if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                (bool rpaid,) = payable(royaltyRecipient).call{value: royaltyAmount}("");
                require(rpaid, "Royalty payment failed");
            }

            // seller
            if (toSeller > 0) {
                (bool spaid,) = payable(seller).call{value: toSeller}("");
                require(spaid, "Seller payment failed");
            }

            // refund extra ETH if msg.value > salePrice
            if (msg.value > salePrice) {
                uint256 refund = msg.value - salePrice;
                (bool refunded,) = payable(msg.sender).call{value: refund}("");
                require(refunded, "Refund failed");
            }
        } else {
            // ERC20 path: use SafeERC20
            IERC20 token = IERC20(paymentToken);

            // transfer full salePrice from buyer to this contract first
            token.safeTransferFrom(msg.sender, address(this), salePrice);

            // distribute: platformFee -> feeRecipient (transfer)
            if (platformFee > 0 && feeRecipient != address(0)) {
                token.safeTransfer(feeRecipient, platformFee);
            }

            // royalty
            if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                token.safeTransfer(royaltyRecipient, royaltyAmount);
            }

            // seller
            if (toSeller > 0) {
                token.safeTransfer(seller, toSeller);
            }
        }

        emit ItemSold(nftContract, tokenId, msg.sender, seller, salePrice, paymentToken);
    }

    // admin functions to update fees
    function setPlatformFeeBps(uint96 newBps) external onlyRole(ADMIN_ROLE) {
        require(newBps <= 1000, "Max 10%");
        platformFeeBps = newBps;
        emit PlatformFeeUpdated(newBps);
    }

    function setListingFeeWei(uint256 newFee) external onlyRole(ADMIN_ROLE) {
        listingFeeWei = newFee;
        emit ListingFeeUpdated(newFee);
    }

    function setFeeRecipient(address payable newRecipient) external onlyRole(ADMIN_ROLE) {
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    // withdraw any accumulated ETH in contract (listing fees, or accidental transfers)
    function withdrawFunds(address payable to) external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 bal = address(this).balance;
        require(bal > 0, "No balance");
        (bool sent,) = to.call{value: bal}("");
        require(sent, "Withdraw failed");
        emit FeesWithdrawn(to, bal);
    }

    // withdraw ERC20 tokens accidentally or leftover (admin)
    function withdrawERC20(address token, address to) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), "Use withdrawFunds for ETH");
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, "No token balance");
        IERC20(token).safeTransfer(to, bal);
    }

    // view helper
    function getListing(address nftContract, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftContract][tokenId];
    }
}
