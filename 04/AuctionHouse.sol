// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    address public highestBidder;
    uint public highestBid;
    uint public auctionEndTime;
    bool public ended;

    mapping(address => uint) public bids;

    constructor(uint _durationSeconds) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _durationSeconds;
    }

    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() public {
        uint amount = bids[msg.sender];
        require(amount > 0, "No funds");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction not finished");
        require(!ended, "Already ended");

        ended = true;
        payable(owner).transfer(highestBid);
    }
}