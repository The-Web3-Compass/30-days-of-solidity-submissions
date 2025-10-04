//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AuctionHouse{
    address public owner;
    string public item;
    uint256 public startBid;
    uint256 public auctionEndTime;

    address private highestBidder;
    uint256 private highestBid;
    bool public ended;

    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor (string memory _item, uint256 _startBid, uint256 _biddingTime){
        owner = msg.sender;
        item = _item;
        startBid = _startBid;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid(uint256 amount) external {
        require(block.timestamp < auctionEndTime, "The auction is over");
        require(amount > startBid, "The bid must be greater than the minimum bid");
        require(amount > bids[msg.sender], "Your bid must be higher than your previous offer.");

        if(bids[msg.sender]== 0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "The auction is not over");
        require(!ended, "The auction is over");
        
        ended = true;
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    function getWinner() external view returns (address, uint256) {
        require(ended, "The auction is not over");
        return (highestBidder, highestBid);
    }
}
