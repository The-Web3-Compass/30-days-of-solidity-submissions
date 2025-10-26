// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    // 拍卖品拥有者
    address public owner;
    // 拍卖的物品
    string public item;
    // 拍卖持续时间
    uint public auctionEndTime;
    // 目前最高的出价者的地址address
    address private highestBidder; // Winner is private, accessible via getWinner
    // 目前最高的价值
    uint private highestBid;       // Highest bid is private, accessible via getWinner
    // 拍卖是否停止
    bool public ended;

    // 不同出价者对应的出价价值
    mapping(address => uint) public bids;
    // 地址数组记录不同的出价者
    address[] public bidders;

    // 先初始化一次拍卖的过程
    constructor(string memory _item, uint _biddingTime) {
        // 是一个全局变量——它给我们提供部署合约的操作者地址
        owner = msg.sender;
        // 拍卖的物品
        item = _item;
        // 拍卖应持续的时间
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // 出价的函数 require() 来设置规则，相当于if判断了，
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        // 判断是否新的竞标者，添加到竞标者列表里
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        // 记录当前的出价
        bids[msg.sender] = amount;

        // 实时保存当前最高的出价
        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    // 如果时间花光了，拍卖状态记录为结束
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");

        ended = true;
    }

    // 获取竞标者列表
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // 检查竞标是否结束，结束了返回最终结果
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
}