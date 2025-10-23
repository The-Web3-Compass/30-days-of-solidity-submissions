// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;          // 追踪部署合约的人
    string public item;            // 拍卖品名称，用双引号""
    uint public auctionEndTime;    // 拍卖持续时间
    address private highestBidder; // Winner is private, accessible via getWinner
    uint private highestBid;       // Highest bid is private, accessible via getWinner
    bool public ended;             // 标记拍卖是否完成

    mapping(address => uint) public bids;  // 用映射记录用户出价
    address[] public bidders;              // 记录出价者地址

    // Initialize the auction with an item and a duration
    constructor(string memory _item, uint _biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;  // 拍卖结束时间=当前时间+持续时间（s）
    }

    // Allow users to place bids
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");             // 确保拍卖还没结束
        require(amount > 0, "Bid amount must be greater than zero.");                        // 确保出价>0
        require(amount > bids[msg.sender], "New bid must be higher than your current bid."); // 确保出价者比其上次出价高

        // Track new bidders(记录新竞标者)
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);      // 存储到竞标者数组中
        }

        bids[msg.sender] = amount;         // 记录出价

        // Update the highest bid and bidder（判断是否为新的最高价者）
        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    // End the auction after the time has expired（拍卖结束）
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");                           // 确保没有人结束拍卖

        ended = true;
    }

    // Get a list of all bidders(查看所有出价者)
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // Retrieve winner and their bid after auction ends（查看获胜者地址及出价）
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
}