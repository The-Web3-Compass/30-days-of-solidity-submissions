//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AuctionHouse {
//need to identify who is running the auction, what are we auctioning, when is it going to end, who is currently winning, has the auction ended yet?
//who places bids and how much? 
address public owner; 
string public item; 
uint public auctionEndTime;
address private highestBidder;
uint private  highestBid; //highest bid
bool public ended;   //was the auction ended?

mapping(address=> uint) public bids;
address[] public bidders;

constructor(string memory _item,uint _biddingTime){
    owner = msg.sender;
    item = _item;
    auctionEndTime = block.timestamp + (_biddingTime * 1 days);//days are multiplied by 24 hours and so on until we get to seconds
 }
//allow users to place bid
function bid (uint amount) external {
    require (block.timestamp>auctionEndTime,"Auction has already ended.");
    require (amount > 0,"Auction amount has to be greater than 0.");
    require (amount > bids[msg.sender],"New bids has to be higher than the last bid.");

 // Track new bidders
if (bids[msg.sender] == 0) {
    bidders.push(msg.sender);
}
bids[msg.sender] = amount;

// Update the highest bid and bidder
if (amount > highestBid) {
    highestBid = amount;
    highestBidder = msg.sender;
}
}
// End the auction after the time has expired 
function endAuction() external {
 require (block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
 require (!ended, "Auction end already called.");
 ended = true;
}
 //Get a list of all bidders
 function getAllBidders() external view returns (address[]memory){
    return bidders;
    }
 // Retrieve winner and their bid after auction ends
 function getWinner() external view returns (address, uint){
    require (ended, "Auction has not ended yet");
    return (highestBidder, highestBid);
 }
}

