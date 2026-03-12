// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AuctionHouse {

    address public highestBidder;
    uint public highestBid;
    uint public auctionEndTime;

    constructor(uint _durationInSeconds) {
        auctionEndTime = block.timestamp + _durationInSeconds;
    }

    function bid() public payable {

        require(block.timestamp < auctionEndTime, "Auction has ended");
        require(msg.value > highestBid, "Bid must be higher than current bid");

        // Refund previous highest bidder
        if (highestBid != 0) {
            (bool sent, ) = payable(highestBidder).call{value: highestBid}("");
            require(sent, "Refund failed");
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function timeLeft() public view returns (uint) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return auctionEndTime - block.timestamp;
        }
    }

    function getWinner() public view returns (address, uint) {
        require(block.timestamp >= auctionEndTime, "Auction still running");
        return (highestBidder, highestBid);
    }
}