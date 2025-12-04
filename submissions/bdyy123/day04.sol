// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract AuctionHouse{
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    mapping(address=> uint) public bids;
    address[] public bidders;
    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    function bid(uint amount) external{
        require(block.timestamp < auctionEndTime, "Aunction has already ended");
        require(amount>0, "Bid amount must be greater than 0");
        require(amount > bids[msg.sender], "New bid must be higher");
        if(bids[msg.sender] == 0 ){
            bidders.push(msg.sender);
        }
        bids[msg.sender] = amount;
        if(amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }    
    }
    function endAuntion() external{
        require(block.timestamp >= auctionEndTime, "Aunction hasnt ended yet");
        require(!ended, "Auction end already calleed");
        ended = true;
    }
    function getAllBidders() external view returns (address[] memory){
        return bidders;
    }
    function getWinner() external view returns (address, uint){
        require(ended,"Auction has not ended yet");
        return (highestBidder, highestBid);
    }
}
