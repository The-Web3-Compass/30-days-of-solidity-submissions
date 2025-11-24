// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AuctionHouse {

    uint public highestBidAmount;
    address public highestBidder;

    uint public auctionStartTime;
    uint public auctionEndingTime;

    constructor() {
        auctionStartTime = block.timestamp;
        auctionEndingTime = block.timestamp + 1 days; //adds 24 hours to the current time
        
        highestBidAmount = 0;
    }

    
    function bid(uint _bidAmount) public payable {
        require(block.timestamp < auctionEndingTime, "Auction ended");
        require(_bidAmount > highestBidAmount, "Bid amount too low");
        if(highestBidAmount != 0) {
            payable(highestBidder).transfer(highestBidAmount);
        }
        highestBidAmount = msg.value;
        highestBidder = msg.sender;
    }

    function getWinner() public view  returns (address){
        require(block.timestamp >= auctionEndingTime, "Auction still Running");      
        return highestBidder;
    }
}
