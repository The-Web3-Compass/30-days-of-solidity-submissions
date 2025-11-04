//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title NFT market
 * @author Eric (https://github.com/0xxEric)
 * @notice A decentralized NFT marketplace with royalties, multi-ERC20 payments, and ERC20 Permit support.
 * @custom:project 30-days-of-solidity-submissions: Day26
 */


import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "./IERC4494.sol";


// // ERC20 permit (EIP-2612) minimal
// interface IERC20Permit {
//     function permit(
//         address owner,
//         address spender,
//         uint256 value,
//         uint256 deadline,
//         uint8 v, bytes32 r, bytes32 s
//     ) external;
// }

contract NFTMarket is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    struct Listing {
        address seller;
        uint256 price; // in wei for ETH, or token units for ERC20
        bool active;
        address paymentToken; // address(0) for ETH, otherwise ERC20 token address
    }

    struct SaleInfo{
        address nftContract; 
        uint256 tokenId;
        address buyer;
         address seller;
         uint256 price;
        address paymentToken;
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
    event ItemSold(SaleInfo saleinfo);
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

// Traditional buy (buyer sends ETH if paymentToken==address(0))
    function buyItem(address nftContract, uint256 tokenId, address paymentToken) external payable nonReentrant {
        _executeBuy(nftContract, tokenId, paymentToken, msg.value, msg.sender);
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


//
// Add ERC20Permit
   function buyItemWithSellerPermit(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 sellerPermitDeadline,
        bytes calldata sellerPermitSig
    ) external payable nonReentrant {
        // 1) call permit on NFT (this will set marketplace as approved for tokenId)
        IERC4494(nftContract).permit(address(this), tokenId, sellerPermitDeadline, sellerPermitSig);

        // 2) proceed to the normal buy flow: ensure listing active, check price, do transfers
        // you can call an internal function that contains the common logic, e.g. _executeBuy(nftContract, tokenId, paymentToken);
        _executeBuy(nftContract, tokenId, paymentToken,msg.value,msg.sender);
    }

    /// @notice Buy item using buyer's ERC20 permit (EIP-2612) in same transaction to avoid prior approve.
    /// Buyer must provide signature (v,r,s) for permit.
    function buyItemWithERC20Permit(
        address nftContract,
        uint256 tokenId,
        address paymentToken, // must be ERC20 that supports EIP-2612
        uint256 value,
        uint256 permitDeadline,
        uint8 v, bytes32 r, bytes32 s
    ) external nonReentrant {
        // call permit on token to allow marketplace to spend buyer's tokens
        IERC20Permit(paymentToken).permit(msg.sender, address(this), value, permitDeadline, v, r, s);

        // proceed to buy; _executeBuy should use ERC20 transferFrom to pull `value`
        _executeBuy(nftContract, tokenId, paymentToken,value, msg.sender);
    }

    function buywithPermit_both_seller_buyer(
        address nftContract,
        uint256 tokenId,
        address paymentToken, // must be ERC20 that supports EIP-2612
        uint256 value,
        uint256 buyerPermitDeadline,
        uint8 v, bytes32 r, bytes32 s,
        uint256 sellerPermitDeadline,
        bytes calldata sellerPermitSig
    ) external nonReentrant{
    //NFT permit：seller approve the NFT for market
    IERC4494(nftContract).permit(address(this), tokenId, sellerPermitDeadline, sellerPermitSig);
    //ERC20 permit：buyer approve the paymenttoken for market
    IERC20Permit(paymentToken).permit(msg.sender, address(this), value, buyerPermitDeadline, v, r, s);
    _executeBuy(nftContract, tokenId, paymentToken,value, msg.sender);
    }

    // --- internal function to execute common buy logic (simplified, adapt from your previous buyItem) ---
       // Internal shared buy logic
    function _executeBuy(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 msgValue,
        address buyer
    ) internal {
        Listing storage l = listings[nftContract][tokenId];
        require(l.active, "Not listed");
        require(l.paymentToken == paymentToken, "Payment token mismatch");

        uint256 salePrice = l.price;
        address seller = l.seller;

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == seller, "Seller no longer owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(seller, address(this)),
                "Marketplace not approved");

        // compute fees
        uint256 platformFee = (salePrice * platformFeeBps) / 10000;

        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);
        try ERC2981(nftContract).royaltyInfo(tokenId, salePrice) returns (address rcpt, uint256 amount) {
            royaltyRecipient = rcpt;
            royaltyAmount = amount;
        } catch {
            royaltyAmount = 0;
            royaltyRecipient = address(0);
        }

        uint256 toSeller;
        unchecked {
            if (platformFee + royaltyAmount > salePrice) {
                toSeller = 0;
            } else {
                toSeller = salePrice - platformFee - royaltyAmount;
            }
        }

        // mark inactive before external calls
        l.active = false;

        // transfer NFT to buyer
        nft.safeTransferFrom(seller, buyer, tokenId);

        // handle payments
        if (paymentToken == address(0)) {
            // ETH path: buyer paid msgValue
            require(msgValue >= salePrice, "Insufficient ETH payment");

            if (platformFee > 0 && feeRecipient != address(0)) {
                (bool pf,) = feeRecipient.call{value: platformFee}("");
                require(pf, "Platform fee transfer failed");
            }
            if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                (bool rpaid,) = payable(royaltyRecipient).call{value: royaltyAmount}("");
                require(rpaid, "Royalty transfer failed");
            }
            if (toSeller > 0) {
                (bool spaid,) = payable(seller).call{value: toSeller}("");
                require(spaid, "Seller transfer failed");
            }

            if (msgValue > salePrice) {
                uint256 refund = msgValue - salePrice;
                (bool refunded,) = payable(buyer).call{value: refund}("");
                require(refunded, "Refund failed");
            }
        } else {
            // ERC20 path
            IERC20 token = IERC20(paymentToken);

            // pull funds from buyer
            token.safeTransferFrom(buyer, address(this), salePrice);

            // distribute
            if (platformFee > 0 && feeRecipient != address(0)) {
                token.safeTransfer(feeRecipient, platformFee);
            }
            if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                token.safeTransfer(royaltyRecipient, royaltyAmount);
            }
            if (toSeller > 0) {
                token.safeTransfer(seller, toSeller);
            }
        }
        SaleInfo memory saleinfo = SaleInfo(nftContract, tokenId, buyer, seller, salePrice, paymentToken);
        emit ItemSold(saleinfo);
    }
}

