// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public highestBidder;
    uint public highestBid;
    uint public auctionEndTime;
    bool public ended;

    constructor(uint _durationInSeconds) {
        auctionEndTime = block.timestamp + _durationInSeconds;
    }

   
    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        require(msg.value > highestBid, "Bid too low");

        if (highestBid != 0) {
           
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    
    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "Auction not ended yet");
        require(!ended, "Auction already ended");

        ended = true;
        
    }
}
