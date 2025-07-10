//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AuctionHouse{

    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder; 
    uint private highestBid;       
    bool public ended;

    address[] public bidders; 
    mapping(address => uint256) public bids;
    
    constructor(string memory newItem, uint256 newBiddingTime)  {
        owner = msg.sender;
        item = newItem;
        auctionEndTime = block.timestamp + newBiddingTime;
    }

    function bid(uint256 newBid) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(newBid > 0, "Bid amount must be greater than zero.");
        require(newBid > bids[msg.sender], "New bid must be higher than your current bid.");
        
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = newBid;

        if (newBid > highestBid) {
            highestBid = newBid;
            highestBidder = msg.sender;
        }

    }
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction has ended.");

        ended = true;
    }

        function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction hasn't ended yet.");
        return (highestBidder, highestBid);   
    }
}