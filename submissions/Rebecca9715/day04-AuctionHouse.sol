// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner; //开启拍卖的人为owner，是公开的
    string public item; //拍卖的物品为item，是公开的
    uint public auctionEndTime; //拍卖结束时间
    address private highestBidder; // 最高价的人的地址为私密，不会显示
    uint private highestBid;       // 最高价为私密
    bool public ended; //拍卖是否结束

    mapping(address => uint) public bids; //出价人和出的价格的map
    address[] public bidders; //出价人的列表

    // 初始化的constructor会在部署之前需要进行设置，比如竞价商品为一幅画，时间为300秒就会填写："painting",300
    // 部署后自动开启拍卖
    constructor(string memory _item, uint _biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // 可以在部署之后切换地址进行bid，更改账户即可
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        // 下面这一步不会在当前报价不超过全部的最高报价时失败，而是会在当定价低于当前用户价格的时候报错
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        // 列表增加地址的同时map中增加，和昨天的题目很像
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        // 最高出价为单独全局变量（区块链中的storage），每次进行更新但不会报错
        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    // 时间到的时候需要手动停止，查询时间是否到的方式：auctionEndTime显示未时间戳，可以转换为我们认识的时间
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");

        ended = true;
    }

    // Get a list of all bidders
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // Retrieve winner and their bid after auction ends
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
}

// Day04
// 账户代表进入不同的address。
// 1. 部署之前需要先填写拍卖品和拍卖结束时间，如"painting",300，点击部署，此时拍卖开始
// 2. 点击auctionEndTime，可以看到拍卖结束时间，时间戳可以转化为我们需要的时间
// 3. 点击bid，可以进行出价，输入价格，点击bid，此时可以查看到出价，出价成功后，可以查看到出价者，出价者可以查看到自己出价成功的拍卖品
// 4. 在上方账户切换账户，可以切换到其他账户，进行出价，出价成功后，可以查看到出价者，出价者可以查看到自己出价成功的拍卖品
// 5. 当拍卖结束时间到之后，手动点击endAuction，可以结束拍卖
// 6. 点击getWinner，可以查看拍卖品最终的归属者