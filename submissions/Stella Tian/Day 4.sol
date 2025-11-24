// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract auction{
 string public item;
 address public owner;
 uint public auctionend;
 uint private highestprice;
 uint public pricegap;
 uint public startprice;
 address private highestbidder;
 bool public ended;
 mapping(address=>uint) public bids;
 address[] public bidders;
 constructor(string memory _item, uint _auctionend,  uint _pricegap, uint _startprice) {
  owner = msg.sender;
  item = _item;
  auctionend = block.timestamp + _auctionend;
  pricegap = _pricegap;
  startprice = _startprice;
 }
 function bid(uint amount) external {
  require(block.timestamp < auctionend, "auction ended");
  require(amount > startprice, "bid amount must need to greater than start price");
  require(amount > bids[msg.sender],"your bid is not higher");
  require(amount > bids[msg.sender]+pricegap, "your bid need to greater than increase range");
  if (bids[msg.sender] == 0){
    bidders.push(msg.sender);
  }
  bids[msg.sender]=amount;
  if (amount > highestprice){
    highestprice = amount;
    highestbidder = msg.sender;
  }
 }
 function endauction() external{
    require(block.timestamp >= auctionend, "auction has not ended yet");
    require(!ended, "auction end already called");
    ended = true;
 }
 function winner() external view returns(address, uint){
  require(ended, "auction has not ended yet");
  return (highestbidder,highestprice);
 }
 function listbidders() external view returns(address[] memory){
  return bidders;
 }
}