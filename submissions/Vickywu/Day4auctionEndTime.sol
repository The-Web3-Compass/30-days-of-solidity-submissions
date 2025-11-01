// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid; // Winner is private, accessible via getWinner
    bool public ended;

    // 新增：起拍价和最低加价百分比（5% = 500 BP）
    uint public constant MIN_BID_INCREMENT = 500; // 5% in basis points (1% = 100 BP)
    uint public reservePrice; // 起拍价

    mapping(address => uint) public bids;
    address[] public bidders;

    constructor(string memory _item, uint _biddingTime, uint _reservePrice) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        reservePrice = _reservePrice;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(!ended, "Auction has ended.");
        require(msg.value > 0, "Bid amount must be greater than zero.");

        // 检查是否达到起拍价
        require(msg.value >= reservePrice, "Bid below reserve price");

        // 检查最低加价规则（新出价必须比当前最高出价高5%）
        if (highestBid > 0) {
            uint minRequiredBid = highestBid + (highestBid * MIN_BID_INCREMENT) / 10000;
            require(msg.value >= minRequiredBid, "Bid too low, must be at least 5% higher");
        }

        // 如果用户已经出价，退还之前的出价
        if (bids[msg.sender] > 0) {
            payable(msg.sender).transfer(bids[msg.sender]);
        }

        // 更新出价记录
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        bids[msg.sender] = msg.value;

        // 更新最高出价
        if (msg.value > highestBid) {
            highestBid = msg.value;
            highestBidder = msg.sender;
        }
    }

    // 新增：允许未中奖者撤回出价
    function withdraw() external {
        require(block.timestamp >= auctionEndTime || ended, "Auction is still active");
        require(bids[msg.sender] > 0, "No bid to withdraw");
        require(msg.sender != highestBidder, "Winner cannot withdraw");

        uint amount = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");
        require(highestBid >= reservePrice, "Reserve price not met");
        ended = true;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }

    // 新增：查看当前最高出价
    function getCurrentHighestBid() external view returns (uint) {
        return highestBid;
    }

    // 新增：查看起拍价
    function getReservePrice() external view returns (uint) {
        return reservePrice;
    }

    //出价的函数
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0,  "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    //查看信息
    function getAllBidders() external view returns (address[] memory) {
    return bidders;
    }

}