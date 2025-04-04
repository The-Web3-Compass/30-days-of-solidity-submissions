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
    address payable public auctionOwner;
    uint public auctionEndTime;
    uint public highestBid;
    address public highestBidder;
    
    // Auction state
    bool public ended;
    
    // Events
    event BidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    
    // Errors
    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();
    
    // Initialize auction with duration (in seconds)
    constructor(uint biddingTime) {
        auctionOwner = payable(msg.sender);
        auctionEndTime = block.timestamp + biddingTime;
    }
    
    // Function to place a bid
    function bid() external payable {
        // Check if auction is still open
        if (block.timestamp > auctionEndTime) {
            revert AuctionAlreadyEnded();
        }
        
        // Check if bid is higher than current highest bid
        if (msg.value <= highestBid) {
            revert BidNotHighEnough(highestBid);
        }
        
        // Update highest bid and bidder
        if (highestBidder != address(0)) {
            // Return previous highest bid
            payable(highestBidder).transfer(highestBid);
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        emit BidIncreased(msg.sender, msg.value);
    }
    
    // Function to end the auction
    function endAuction() external {
        // Check if auction end time has been reached
        if (block.timestamp < auctionEndTime) {
            revert AuctionNotYetEnded();
        }
        
        // Check if auction has already been ended
        if (ended) {
            revert AuctionEndAlreadyCalled();
        }
        
        // Mark auction as ended
        ended = true;
        
        // Send the highest bid to the auction owner
        auctionOwner.transfer(highestBid);
        
        emit AuctionEnded(highestBidder, highestBid);
    }
    
    // Helper function to check time remaining
    function timeRemaining() external view returns (uint) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return auctionEndTime - block.timestamp;
        }
    }
}