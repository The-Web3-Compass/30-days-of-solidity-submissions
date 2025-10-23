// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AuctionHouse {
    address public owner;
    address public highestBidder;
    uint public highestBid;
    uint public auctionEndTime;
    bool public auctionEnded;

    mapping(address => uint) public bids;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint _biddingTime) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime; // e.g., 60 seconds auction
    }

    // place a bid
    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction already ended!");
        require(msg.value > highestBid, "There already is a higher bid!");

        // refund the previous highest bidder
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // withdraw your refund if you were outbid
    function withdraw() external returns (bool) {
        uint amount = bids[msg.sender];
        require(amount > 0, "No funds to withdraw");
        bids[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        return success;
    }

    // end the auction and send the highest bid to owner
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended!");
        require(!auctionEnded, "Auction already ended!");

        auctionEnded = true;
        emit AuctionEnded(highestBidder, highestBid);

        payable(owner).transfer(highestBid);
    }
}
