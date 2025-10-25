// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder; 
    uint private highestBid;       
    bool public ended;

    mapping(address => uint) public bids;
    mapping(address => uint) public pendingReturns;
    address[] public bidders;

    uint public startingBid;
    uint public minIncrementPercent;


    constructor(string memory _item, uint _biddingTime,uint _startingBid,uint _minIncrementPercent) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        startingBid = _startingBid;
        minIncrementPercent = _minIncrementPercent;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > 0, "Send ETH to place a bid.");
        
        uint newTotal = bids[msg.sender] + msg.value;

        if (highestBid == 0) {
            require(newTotal>=startingBid,"Bid must be at least the starting bid.");
        }else {
            uint minRequired = highestBid+(highestBid*minIncrementPercent)/100;
            require(newTotal>=minRequired,"Bid must meet minimum increment.");
        }

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = newTotal;

        if (newTotal > highestBid) {
            if (highestBidder != address(0) && highestBidder != msg.sender) {
                pendingReturns[highestBidder] += highestBid;
            }
            highestBid = newTotal;
            highestBidder = msg.sender;
        }

    }

    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw.");
        pendingReturns[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Withdraw failed.");
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");

        ended = true;
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
}
