// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract AuctionHouse {

    address public owner;
    string public item;
    uint256 public auctionEndTime;
    uint256 private  highestBid;
    address private  highestBidder;
    bool public auctionEnded;

    mapping(address => uint256) public bids;     
    address[] public bidders;

    // Constructor to initialize the auction
    constructor(string memory _item, uint _biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // Allow users to place bids
    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > 0, "Bid amount must be greater than zero.");
        require(msg.value > bids[msg.sender], "New bid must be higher than your current bid.");

        // Track new bidders
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = msg.value;

        // Update the highest bid and bidder
        if (msg.value > highestBid) {
            highestBid = msg.value;
            highestBidder = msg.sender;
        }
    }

    // Withdraw funds from the auction
    function withdraw() external  {  
        require(bids[msg.sender] > 0, "No funds to withdraw.");
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw.");
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(msg.sender != owner, "Owner cannot withdraw.");

        uint256 amount = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }


    // End the auction after the time has expired
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!auctionEnded, "Auction end already called.");

        auctionEnded = true;
    }

    // Get a list of all bidders
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // Retrieve winner and their bid after auction ends
    function getWinner() external view returns (address, uint) {
        require(auctionEnded, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
    
}
