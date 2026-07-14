// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    uint public startingPrice;      // 起拍价
    uint public minIncrementRate;   // 最低加价比例（百分比）
    address private highestBidder;  // 当前最高出价者
    uint private highestBid;        // 当前最高出价金额
    bool public ended;

    mapping(address => uint) public bids;
    address[] public bidders;

    constructor(
        string memory _item,
        uint _biddingTime,
        uint _startingPrice,
        uint _minIncrementRate
    ) {
        require(_startingPrice > 0, "Starting price must be greater than zero.");
        require(_minIncrementRate > 0, "Increment rate must be greater than zero.");
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        startingPrice = _startingPrice;
        minIncrementRate = _minIncrementRate;
    }

    // 出价逻辑
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount >= startingPrice, "Bid must be at least the starting price.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        uint minRequiredBid = highestBid == 0
            ? startingPrice
            : highestBid + (highestBid * minIncrementRate / 100);
        require(amount >= minRequiredBid, "Bid must be at least the minimum increment.");

        // 首次出价记录
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        // 更新最高价
        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    // 允许未中标者撤回出价
    function withdraw() external {
        require(ended, "Auction not yet ended.");
        require(msg.sender != highestBidder, "Winner cannot withdraw.");
        uint amount = bids[msg.sender];
        require(amount > 0, "No bid to withdraw.");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // 拍卖结束
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction already ended.");
        ended = true;

        // 将中标金额转给拍卖发起人
        if (highestBid > 0) {
            payable(owner).transfer(highestBid);
        }
    }

    // 获取所有出价者
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // 获取获胜者和出价金额
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }


}