/*---------------------------------------------------------------------------
  File:   AuctionHouse.sol
  Author: Marion Bohr
  Date:   04/04/2025
  Description:
    Create a basic auction! Users can bid on an item, and the highest bidder 
    wins when time runs out. You'll use 'if/else' to decide who wins based on 
    the highest bid and track time using the blockchain's clock 
    (`block.timestamp`). This is like a simple version of eBay on the 
    blockchain, showing how to control logic based on conditions and time.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract AuctionHouse {
    // Auction parameters
    address public auctionOwner;
    string public auctionItem;
    uint256 public auctionEndTime;

    // Current state
    uint256 public highestBid;
    address public highestBidder;
    bool public ended;

    
    // Track funds to be refunded to overbid participants
    mapping(address => uint256) public returnsOwed;

    // Constructor to initialize auction with item and duration
    constructor(string memory _auctionItem, uint256 _durationInSeconds) {
        auctionOwner = msg.sender; // The address deploying the contract is the auction owner
        auctionItem = _auctionItem; // The item being auctioned
        auctionEndTime = block.timestamp + _durationInSeconds; // Auction end time is calculated
    }

    // Place a bid on the auction
    function placeBid(uint256 bidAmount) public {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(bidAmount > highestBid, "Bid is not higher than the current highest bid.");

        // If there was a previous highest bidder, refund them the previous bid amount
        if (highestBid > 0) {
            returnsOwed[highestBidder] += highestBid;
        }

        // Update the highest bid and highest bidder
        highestBid = bidAmount;
        highestBidder = msg.sender;
    }

    // Allow overbid participants to withdraw their previous bids
    function collectRefund() public {
        uint256 amount = returnsOwed[msg.sender];
        require(amount > 0, "No funds available for refund.");

        returnsOwed[msg.sender] = 0;
        // Refund logic removed (no payable transfers)
    }

    // End the auction
    function finishAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!ended, "Auction has already been concluded.");

        ended = true; // Mark the auction as ended
        // Transfer logic removed (no payment to auction owner)
    }
}