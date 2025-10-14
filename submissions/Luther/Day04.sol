//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AuctionHouse{

    address public owner;     //对外公开可读,记录谁是合约发布者or所有者
    string public item;     //存放拍卖的物体名称，对外公开可读
    uint public auctionEndTime;     //存放拍卖的结束时间。以秒为单位的时间戳
    address private highestBidder;     //保存当前最高出价者的地址
    uint public highestBid;     //保存当前最高出价的数额
    bool public ended;     //标志拍卖是否已经结束

    mapping(address => uint) public bids;     //外部可查询某地址当前记录的出价
    address[] public bidders;     //记录所有已出价的地址

    constructor(string memory _item, uint _biddingTime) {
        owner = msg.sender;     //将owner设为msg.sender部署合约的外部地址，记录合约的所有者or发布者
        item = _item;     //保存拍卖物品信息
        auctionEndTime = block.timestamp + _biddingTime;     //确定拍卖的截止时间戳
    }

    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");     //检查当前时间是否早于拍卖截止时间，若不满足则回退并弹出“”
        require(amount > 0, "Bid amount must be greater than zero.");     //检查出价是否大于0，若不满足则回退并弹出“”
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");     //要求本次出价必须高于前面的出价，否则回退并弹出“”

        if (bids[msg.sender] == 0) {     //判断调用者在bids中之前是否出价，若第一次出价，进入条件体
            bidders.push(msg.sender);     //将调用者地址添加到bidders数组中，记录该地址为参与者之一，（仅第一次是记录）
        }

        bids[msg.sender] = amount;     //将调用者的出价数额存入bids映射，更新改地址的当前出价记录

        if (amount > highestBid) {     //检查本次出价是否高于当前记录，如果是则更新
            highestBid = amount;     
            highestBidder = msg.sender;     
        }
    }

    function endAuction() external {     //结束拍卖
        require(block.timestamp >= auctionEndTime, "Auction hasn't erned yet.");     //要求当前时间已到或超过拍卖结束时间，否则回退并弹出“”
        require(!ended, "Auction end already called.");

        ended = true;
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction hasn't erned yet.");     //要求拍卖已结束，否则回退并弹出
        return(highestBidder, highestBid);     //返回当前记录的地址和数额
    }


}