// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract auctionHouse{
    address  owner;          
string  item;             
uint  auctionEndTime;     
address private highestBidder;  
uint private highestBid;        
bool  ended;              
mapping(address => uint)  bids;  
address[]  bidders;  
    

   constructor(string memory _item) {
    owner = msg.sender;
    item = _item;
    auctionEndTime = block.timestamp + 5 minutes;
}

    function bid(uint amount) external {
    require(block.timestamp < auctionEndTime, "Auction has already ended.");
    require(amount > 0, "Bid amount must be greater than zero.");
    require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

    if (bids[msg.sender] == 0) {
        bidders.push(msg.sender);
    }

    bids[msg.sender] = amount;

    if (amount > highestBid) {
        highestBid = amount;
        highestBidder = msg.sender;
    }
}

   function endAuction() external {
    require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
    require(!ended, "Auction end already called.");
    ended = true;
}

   function getWinner() external view returns(address, uint){
      require(ended, "Auction hasn't ended yet.");
       return (highestBidder, highestBid);
   }
}