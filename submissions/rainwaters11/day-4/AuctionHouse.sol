/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    // State variables
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    bool public ended;

    // Events to notify the outside world
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    // When we deploy, we set how many seconds the auction will run
    constructor(uint256 _durationInSeconds) {
        // block.timestamp is the current network time
        auctionEndTime = block.timestamp + _durationInSeconds;
    }

    // The main bidding logic
    function bid(uint256 bidAmount) public {
        // 1. Time Check
        require(block.timestamp <= auctionEndTime, "The auction has already ended!");

        // 2. Control Flow: If/Else Check
        if (bidAmount > highestBid) {
            // We have a new highest bidder!
            highestBid = bidAmount;
            highestBidder = msg.sender;
            
            emit HighestBidIncreased(msg.sender, bidAmount);
        } else {
            // The bid wasn't high enough
            revert("Bid is not high enough to win.");
        }
    }

    // Function to officially close out the auction
    function endAuction() public {
        // Time Check: Ensure time has actually run out
        require(block.timestamp >= auctionEndTime, "The auction is still running.");
        require(!ended, "The auction has already been finalized.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }
}