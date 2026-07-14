// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AuctionHouse
 * @author Nadiatus Salam
 * @notice A simple time-bound auction using if/else logic and block.timestamp.
 * @dev Demonstrates: if/else control flow, time checks, and a secure bidding pattern.
 */
contract AuctionHouse {
    // Seller (auction owner)
    address public immutable seller;

    // Auction end time (unix timestamp, seconds)
    uint64 public immutable endTime;

    // Current highest bid and bidder
    address public highestBidder;
    uint256 public highestBid;

    // Track whether the auction has been finalized
    bool public ended;

    // Outbid bidders can withdraw their previous bids (pull-over-push pattern)
    mapping(address => uint256) public pendingReturns;

    // Events
    event Started(uint64 endTime);
    event BidPlaced(address indexed bidder, uint256 amount);
    event Withdrawn(address indexed bidder, uint256 amount);
    event Ended(address indexed winner, uint256 amount);

    // Custom errors for gas efficiency
    error SellerCannotBid();
    error BidTooLow();
    error AuctionEnded();
    error AuctionNotEnded();
    error NoPendingReturn();
    error WithdrawFailed();
    error DirectEtherNotAllowed();

    /**
     * @param durationSeconds The auction duration in seconds from deployment time.
     */
    constructor(uint64 durationSeconds) {
        seller = msg.sender;
        endTime = uint64(uint256(uint64(block.timestamp)) + durationSeconds);
        emit Started(endTime);
    }

    /**
     * @notice Place a bid. Must be strictly higher than the current highest bid.
     * @dev Uses pull-over-push refunds to avoid reentrancy vulnerabilities.
     */
    function bid() external payable {
        if (block.timestamp >= endTime || ended) revert AuctionEnded();
        if (msg.sender == seller) revert SellerCannotBid();
        if (msg.value <= highestBid) revert BidTooLow();

        if (highestBidder != address(0)) {
            // Accrue refund for the previously highest bidder
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw a previously outbid amount.
     * @dev Checks-effects-interactions: zero-out credit before transferring.
     */
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) revert NoPendingReturn();

        pendingReturns[msg.sender] = 0;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        if (!ok) {
            // Restore state if transfer fails
            pendingReturns[msg.sender] = amount;
            revert WithdrawFailed();
        }

        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Finalize the auction after time has passed. Anyone can call.
     * @dev Uses if/else to determine the outcome and payout.
     */
    function endAuction() external {
        if (ended) revert AuctionEnded();
        if (block.timestamp < endTime) revert AuctionNotEnded();

        ended = true;

        // Decide the outcome using if/else
        if (highestBidder == address(0)) {
            // No valid bids — nothing to pay out
            emit Ended(address(0), 0);
        } else {
            // Transfer funds to the seller
            (bool ok, ) = payable(seller).call{value: highestBid}("");
            if (!ok) revert WithdrawFailed();
            emit Ended(highestBidder, highestBid);
        }
    }

    /**
     * @notice Returns seconds left until the auction ends.
     * @return Seconds remaining, or 0 if the auction has already ended.
     */
    function timeLeft() external view returns (uint256) {
        if (block.timestamp >= endTime) return 0;
        return endTime - block.timestamp;
    }

    // Block accidental ETH sends
    receive() external payable {
        revert DirectEtherNotAllowed();
    }

    fallback() external payable {
        revert DirectEtherNotAllowed();
    }
}