// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    // 出价人、出价多少列表
    address public owner;           // 拍卖人地址
    string public item;             // 拍卖物
    uint public auctionEndTime;     // 拍卖截止时间
    address private highestBidder;  //最高出价者地址
    uint public highestBid;         // 最高出价
    bool public ended;              //拍卖是否结束 结束true 未结束false
    mapping(address => uint) public bids; //每个用户地址的出价
    address[] public bidders; // 出价人地址列表 即参与人列表

    // 初始化钩子函数
    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime; //block.timestamp 当前时间 + 活动持续时间(以s为单位) = 活动结束时间
    }
    // 用户出价
    function bid(uint amount) external{
        // require 满足继续执行，不满足报错
        // 是否在活动持续时间
        require(block.timestamp < auctionEndTime, "Auciton has already ended.");
        // 出价是否大于0
        require(amount > 0, "Bid must be greater then zero.");
        // 新的出价必须高于当前最高出价
        require(amount > bids[msg.sender], "New bid must be higher then your current bid.");
        // 记录地址出价
        bids[msg.sender] = amount;
        // 是否更新最高出价
        if(amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }
        // 查看出价用户是否第一次出价，第一次的话 保存近bidders出价人列表
        if(bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }
    }
    // 拍卖结束
    function endAuction() external{
        // 是否已过拍卖时间
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        // 是否已经结束
        require(!ended, "Auction end already called.");
        ended = true;
    }
    // 拍卖结束后查看拍卖信息
    function getWinner() external view returns(address, uint) {
        require(ended, "Aution has not ended yet.");
        return (highestBidder, highestBid);
    }
    // 拍卖结束后查看所有的出价人
    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }
}