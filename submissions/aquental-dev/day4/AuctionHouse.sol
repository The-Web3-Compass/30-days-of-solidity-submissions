// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    // Auction parameters
    address public auctioneer;
    uint256 public auctionEndTime;
    uint256 public constant DEFAULT_AUCTION_DURATION = 1 days;
    uint256 public constant MAX_AUCTION_DURATION = 10 days;

    // Current state of the auction
    address public highestBidder;
    uint256 public highestBid;
    bool public ended;

    // Events to log auction activities
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    // Mapping to track bids for refund purposes
    mapping(address => uint256) public pendingReturns;

    // Constructor to initialize the auction
    // Sets the auctioneer and determines the auction end time based on input duration
    constructor(uint256 _duration) {
        auctioneer = msg.sender;
        uint256 duration = _duration > 0 ? _duration : DEFAULT_AUCTION_DURATION;
        if (duration > MAX_AUCTION_DURATION) {
            auctionEndTime = block.timestamp + MAX_AUCTION_DURATION;
        } else {
            auctionEndTime = block.timestamp + duration;
        }
    }

    // Allows users to place a bid on the auction
    // Requires the bid to be higher than the current highest bid and the auction to be ongoing
    function bid() public payable {
        // Check if auction is still ongoing
        if (block.timestamp > auctionEndTime) {
            revert("Auction has already ended");
        }

        // Check if bid is higher than current highest bid
        if (msg.value <= highestBid) {
            revert("Bid is not high enough");
        }

        // Store previous highest bidder's bid for refund
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        // Update highest bidder and bid
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // Allows outbid users to withdraw their funds
    // Returns true if withdrawal is successful, false otherwise
    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // Ends the auction and transfers the highest bid to the auctioneer
    // Can only be called after the auction end time and if the auction hasn't already ended
    function endAuction() public {
        // Check if auction has already ended
        if (ended) {
            revert("Auction has already ended");
        }

        // Check if auction time has passed
        if (block.timestamp < auctionEndTime) {
            revert("Auction has not yet ended");
        }

        // Mark auction as ended
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // Transfer highest bid to auctioneer
        if (highestBid > 0) {
            payable(auctioneer).transfer(highestBid);
        }
    }
}
