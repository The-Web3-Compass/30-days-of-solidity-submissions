// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract AuctionHouse {
    mapping (address => uint) public bids;
    address public highestBidder;
    uint public highestBid;
    address public owner;
    uint256 public auctionEndTime;

    constructor(uint256 _biddingTime) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function placeBid() external payable {
        require(msg.value > highestBid, "Bid must be higher than current highest bid");
        require(block.timestamp < auctionEndTime, "Auction has ended");

        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        bids[msg.sender] += msg.value;
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    function withdraw() external {
        uint amount = bids[msg.sender];
        require(amount > 0, "No funds to withdraw");
        require(block.timestamp > auctionEndTime, "Auction is still ongoing");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction() external {
        require(msg.sender == owner, "Only owner can end the auction");
        require(highestBidder != address(0), "No bids placed");

        // Transfer the highest bid to the owner
        payable(owner).transfer(highestBid);

        // Reset the auction state
        highestBidder = address(0);
        highestBid = 0;
    }
}