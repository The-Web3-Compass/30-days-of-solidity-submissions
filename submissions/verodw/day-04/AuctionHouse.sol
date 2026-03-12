// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract AuctionHouse {
    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended;

    mapping ( address => uint256 ) public bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid(uint256 amount) external payable {
        require(block.timestamp < auctionEndTime, "Auction has ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        if(bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;
        if(amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external{
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction has already ended.");
        ended = true;
    }

    function getWinner() external view returns(address, uint256){
        require(ended, "Auction hasn't ended yet.");
        return (highestBidder, highestBid);
    } 

    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }
}
