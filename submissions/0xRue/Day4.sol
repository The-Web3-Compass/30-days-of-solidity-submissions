// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;//存储账户地址
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;
    address[] public bidders;//出价者
    mapping(address => uint) public bids;

    //构造函数（点deploy的条件）
    constructor(string memory _item, uint _biddingTime) {
        owner = msg.sender;//msg.sender表示当前调用函数的用户地址
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender],  "New bid must be higher than your current bid.");//出价就是一次交易
        
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        bids[msg.sender] = amount;//一个人只保留最高出价

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

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }

    function getALLBidders() external view returns(address[] memory) {
        return bidders;
    }
}
