// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended;

    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    function bid(uint256 amount) external {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        require(amount > 0, "Bidding amount must be > 0");
        require(amount > bids[msg.sender], "Bid must be higher than the previous bid");

        if(bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }
        bids[msg.sender] = amount;

        if(amount > highestBid){
            highestBid= amount;
            highestBidder = msg.sender; 
        }
    }
    function endAuction() external{
        require(block.timestamp >= auctionEndTime, "Auction has not yet ended");
        require(!ended, "No more bidding");
        ended = true;
    }
    function getWB() external view returns(address, uint256){
        require(ended, "Auction has not yet ended");
        return (highestBidder, highestBid);
    }
    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }
}