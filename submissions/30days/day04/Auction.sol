// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction{
 address public owner;           // who created auction
 string public item;             //auction item 
 uint256 auctionEndTime;         //when biding stop
 address private highestBidder;  // highest didder
 uint256 private highestBid;     // Winning bid amount
 bool public ended;              //has auction been finalized.
 mapping(address => uint256) public bids; //every one's current bids
 address[] public bidders;        // list of all bidders

 constructor(string memory _item, uint256 _biddingTime){
    owner = msg.sender;
    item = _item;
    auctionEndTime = block.timestamp +_biddingTime;
 }
 function bid(uint256 amount) external {
    require(block.timestamp < auctionEndTime,"Auction alredy ended.");
    require(amount > 0,"Bid amount must be greater then ZERO.");
    require(amount > bids[msg.sender],"New bid must be higher then current bid.");

    if(bids[msg.sender] == 0){
        bidders.push(msg.sender);
    }
    bids[msg.sender] = amount;
    if(amount > highestBid){
        highestBid = amount;
        highestBidder = msg.sender;
    }

}
function endAution()external{
    require(block.timestamp >= auctionEndTime,"Auction hasn't ended.");
    require(!ended,"Auction end alredy called.");

    ended = true;
}
function getWinner() public view returns(address, uint256){
    require(ended,"Auction has not ended yet.");
    return (highestBidder,highestBid);
}

}