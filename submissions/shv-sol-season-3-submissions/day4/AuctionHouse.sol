// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AuctionHouse
 * @dev A basic auction contract where users can place bids.
 * The highest bid wins when the auction ends after a fixed duration.
 * Uses block.timestamp for timing and simple if/else logic for bid comparison.
 */


contract AuctionHouse {
    address public seller;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;

    bool public ended;

    constructor(uint _durationInSeconds) {
        seller = msg.sender;
        auctionEndTime = block.timestamp + _durationInSeconds;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There already is a higher bid.");

        // Refund previous highest bidder
        if (highestBid > 0) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "Auction already ended.");

        ended = true;

        // Send highest bid to the seller
        payable(seller).transfer(highestBid);
    }
}
