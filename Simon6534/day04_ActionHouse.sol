// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner; //所有者
    string public item; // 拍卖的物品
    uint public auctionEndTime; // 拍卖结束时间
    address private highestBidder; // 最高出价者的钱包地址
    uint private highestBid; // 最高出价
    bool public  auctionHasEnd; // 拍卖结束标志
    mapping (address => uint) public bids; // 所有人的出价
    address[] public bidders; // 所有参与出价的人的名单

    constructor(string memory _item, uint _binddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _binddingTime;
    }

    // 用户出价
    function bind(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount  must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");
        // 第一次出价，记录地址
        if(bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }
        bids[msg.sender] = amount;
        if(amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    // 结束拍卖
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Action hasn't  ended yet.");
        require(!auctionHasEnd, "Auction end already called.");
        auctionHasEnd = true;
    }

    // 显示获胜者
    function getWinner() external view returns (address, uint){
        require(auctionHasEnd, "Auction hasn't endded yet.");
        return (highestBidder, highestBid);
    }
    
    // 显示所有出价者
    function getAllBidder() external view returns (address[] memory) {
        return bidders;
    }
}