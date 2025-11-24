//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    mapping (address => uint)public bids;
    address[] public bidders;

    constructor(string memory_item, uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timstamp + _biddingTime;
    }

    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime);
        require(amount > 0);
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        if (bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        if (amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
            }
    }
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");

        ended = true;
    }

    function getAllBidders() external view returns (address[] memory){
        return bidders;
    }

    function getWinnder() external view returns (address, uint){
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
