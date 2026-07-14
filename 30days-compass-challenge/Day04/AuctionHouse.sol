// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    // State variables
    address public seller;
    string public itemName;
    uint256 public auctionEndTime;
    
    address public highestBidder;
    uint256 public highestBid;
    
    bool public auctionEnded;
    
    // Mapping to track bids for refunds
    mapping(address => uint256) public pendingReturns;
    
    // Events
    event NewHighestBid(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    
    // Constructor - sets up the auction
    constructor(string memory _itemName, uint256 _durationMinutes) {
        seller = msg.sender;
        itemName = _itemName;
        // Set auction end time (current time + duration)
        auctionEndTime = block.timestamp + (_durationMinutes * 1 minutes);
    }
    
    // Function to place a bid
    function bid() public payable {
        // Check if auction is still active
        if (block.timestamp > auctionEndTime) {
            revert("Auction has ended");
        }
        
        // Check if bid is higher than current highest
        if (msg.value <= highestBid) {
            revert("Bid must be higher than current highest bid");
        }
        
        // If there was a previous highest bidder, add their bid to pending returns
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        // Update highest bid and bidder
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        emit NewHighestBid(msg.sender, msg.value);
    }
    
    // Function to withdraw a losing bid
    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        
        if (amount > 0) {
            // Reset the pending return before sending to prevent re-entrancy
            pendingReturns[msg.sender] = 0;
            
            // Send the funds back
            if (!payable(msg.sender).send(amount)) {
                // If send fails, restore the pending return
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    // Function to end the auction
    function endAuction() public {
        // Check if auction time has passed
        if (block.timestamp < auctionEndTime) {
            revert("Auction has not ended yet");
        }
        
        // Check if auction already ended
        if (auctionEnded) {
            revert("Auction already ended");
        }
        
        // Mark auction as ended
        auctionEnded = true;
        
        emit AuctionEnded(highestBidder, highestBid);
        
        // Transfer funds to seller
        if (highestBid > 0) {
            payable(seller).transfer(highestBid);
        }
    }
    
    // View function to check time remaining
    function timeRemaining() public view returns (uint256) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return auctionEndTime - block.timestamp;
        }
    }
    
    // View function to check if auction is active
    function isActive() public view returns (bool) {
        if (block.timestamp > auctionEndTime || auctionEnded) {
            return false;
        } else {
            return true;
        }
    }
}