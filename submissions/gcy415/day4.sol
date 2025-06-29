// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AunctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    mapping (address => uint) public bids;
    address[] public bidders;

    // initialize the auction with an item and a duration
    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // Allow users to place bids
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Aunction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        //track new bidders
        if (bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        // update the highest bid and bidder
        if (amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }
    // End the auction after the time has expired
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction already ended");
        ended = true;
    }

    // Get a list of all bidders
    function getAllBidders() external view returns (address[] memory){
        return bidders;
    }

    // Retrieve winner and their vid after auction ends
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
}