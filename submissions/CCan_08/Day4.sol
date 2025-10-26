// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint public auctionEndtime;
    address private highestbidder;
    uint private  highestbid;
    bool public ended;
    //状态变量设置

mapping(address=>uint) public bids; //记录出价
address[] public bidders; //记录竞标者

constructor(string memory _item, uint _biddingTime) {
    owner = msg.sender;
    item = _item;
    auctionEndtime = block.timestamp + _biddingTime;//当前时间+持续时间
}
    
function bid(uint amount) external {
require(block.timestamp < auctionEndtime, "Auction has already ended.");
require(amount > 0, "Bid amount must be greater than zero.");
require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

if (bids[msg.sender] == 0) {
    bidders.push(msg.sender);
}

bids[msg.sender] = amount;

if (amount > highestbid) {
    highestbid = amount;
    highestbidder = msg.sender;
}
}

function endAuction() external {//结束拍卖
    require(block.timestamp >= auctionEndtime, "Auction hasn't ended yet.");
    require(!ended, "Auction end already called.");

    ended = true;
}

function getAllBidders() external view returns (address[] memory) {//返回信息
    return bidders;
}
function getWinner() external view returns (address, uint) {
    require(ended, "Auction has not ended yet.");
    return (highestbidder, highestbid);
}
}
