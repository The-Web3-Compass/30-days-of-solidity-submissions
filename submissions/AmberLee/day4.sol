//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract AusctionHouse{

    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    bool public ended;
    uint256 public highestBid;

    mapping (address => uint256) public bids;
    address [] public bidders;

    constructor(string memory _item, uint256 _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;

    }

    function bid(uint256 amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended" );
        require(amount >= bids[msg.sender],"Bid is too low:");
        require(amount > 0, "Bid amount must be greater than zero");
    
    if(bids[msg.sender]==0){
        bidders.push(msg.sender);
    }

    bids[msg.sender] = amount;

    if (amount > highestBid){
        highestBid = amount;
        highestBidder = msg.sender;

    }
    }

    function endAuction () external {
        require (block.timestamp >= auctionEndTime, "Auction hasn't ended.");
        require (!ended, "Auction end already called.");
        ended = true;
    }

    function getWinner () external view returns (address, uint){
        require (!ended, "Auction has ended");
        return (highestBidder, highestBid);
    }
}