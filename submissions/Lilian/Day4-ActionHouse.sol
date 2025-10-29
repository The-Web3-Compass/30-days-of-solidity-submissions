// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionendtime;
    address private higgestBidder;
    uint private higgestBid;
    bool public ended;

    mapping (address=>uint) public bids;
    address[] public bidders;

    constructor(string storage memory_item,uint _biddingTime){
        owner=msg.sender;
        item=item;
        auctionendtime=block.timestamp+_biddingtime;
   }
   function bid (uint amount)external {
    require(block.timestamp<auctionendtime);"Auction has ended";
    require(amount>0,"Bid amount must be greater than zero");
    require(amount>bids[msg.sender]);
   }
   bids[msg.sender]_amount;

   if (amount>higgestBid){
    higgestBid=amount;
    higgestBidder=msg.sender;
   }
}
function endAuction()external {
    require(block.timestamp>=auctionendtime,"Auction hasn't ended yet");
    require(!ended,"Auction end already called");

    ended=true;
}
function getallbidders()external view returns (address[] memory){
    return bidders;
}
function getwinner()external view returns(address,uint){
    require(ended,"Auction has not ended yet");
    return (highestbidder,highestbid);
}
