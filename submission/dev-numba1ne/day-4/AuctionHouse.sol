// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder; // Winner is private, accessible via getWinner
    uint private highestBid;       // Highest bid is private, accessible via getWinner
    bool public ended;
    uint public startingPrice;     // Added starting price
    uint public minIncrement;      // Minimum increment percentage (in basis points, 1/100 of a percent)
    
    mapping(address => uint) public bids;
    address[] public bidders;

    // Initialize the auction with an item, duration, starting price and minimum increment
    constructor(string memory _item, uint _biddingTime, uint _startingPrice, uint _minIncrementBps) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        startingPrice = _startingPrice;
        minIncrement = _minIncrementBps; // 500 = 5%
        highestBid = _startingPrice - 1; // Set to just below starting price
    }

    // Allow users to place bids
    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > 0, "Bid amount must be greater than zero.");
        
        uint newBidAmount = bids[msg.sender] + msg.value;
        
        // First bid must be at least the starting price
        require(newBidAmount >= startingPrice, "Bid must be at least the starting price.");
        
        // New bid must be higher than the user's current bid
        require(newBidAmount > bids[msg.sender], "New bid must be higher than your current bid.");
        
        // Calculate minimum required bid based on current highest bid
        uint minRequiredBid = highestBid + (highestBid * minIncrement) / 10000;
        
        // If this is a new highest bid, it must meet minimum increment requirement
        if (newBidAmount > highestBid) {
            require(newBidAmount >= minRequiredBid, "Bid increment too small.");
            highestBid = newBidAmount;
            highestBidder = msg.sender;
        }
        
        // Track new bidders
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        
        bids[msg.sender] = newBidAmount;
    }

    // End the auction after the time has expired
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");
        ended = true;
    }
    
    // Allow bidders to withdraw their bids if they didn't win
    function withdrawBid() external {
        require(ended, "Auction has not ended yet.");
        require(msg.sender != highestBidder, "Winner cannot withdraw their bid.");
        
        uint bidAmount = bids[msg.sender];
        require(bidAmount > 0, "No bid to withdraw.");
        
        // Reset the bid before sending to prevent reentrancy
        bids[msg.sender] = 0;
        
        // Transfer the bid amount back to the bidder
        (bool success, ) = payable(msg.sender).call{value: bidAmount}("");
        require(success, "Failed to send Ether.");
    }

    // Get a list of all bidders
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // Retrieve winner and their bid after auction ends
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
    
    // Allow the owner to withdraw the highest bid after auction ends
    function withdrawFunds() external {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        require(ended, "Auction has not ended yet.");
        require(highestBid > 0, "No funds to withdraw.");
        
        uint amount = highestBid;
        highestBid = 0; // Prevent re-entrancy
        
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Failed to send Ether.");
    }
}
