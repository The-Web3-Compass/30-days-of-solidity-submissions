 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;  //拍卖人
    string public item;    //拍卖物
    uint public auctionEndTime; //拍卖持续时间
    address private highestBidder; //最高出价者地址
    uint private highestBid;  //最高出价
    bool public ended;  //拍卖是否结束
    uint public minBidIncrement = 5; // 最低增量百分比，默认为5%
    uint public startingPrice; // 起始价格

    mapping(address => uint) public bids;
    address[] public bidders;
    mapping(address => bool) public withdrawn; // 记录用户是否已撤回出价

    //初始化结构体
    //_biddingTime表示当前拍卖应运行的时间, block.timestamp + _biddingTime表示拍卖截至时间
    constructor(string memory _item, uint _biddingTime, uint _startingPrice){
        owner = msg.sender;
        item = _item;
        auctionEndTime  = block.timestamp + _biddingTime;
        startingPrice = _startingPrice;
    }

    //竞价
    function bid(uint amount) external payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must greater than zero");
        require(amount >= startingPrice, "Bid amount must be at least the starting price");
        require(amount > bids[msg.sender], "New bid must be higher than current bid");
        
        // 检查最低增量规则
        if (amount > highestBid) {
            uint minNewBid = highestBid + (highestBid * minBidIncrement / 100);
            require(amount >= minNewBid, "Bid must be at least 5% higher than current highest bid");
        }

        //用户初次出价设置
        if (bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }
        bids[msg.sender] = amount;
        
        // 确保用户发送了足够的以太币
        require(msg.value >= amount, "Not enough ETH sent");

        //竞价后设置
        if (amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }

    }

    //结束拍卖
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't end yet");
        require(!ended, "Auction already end");

        ended = true;

    }

    //拍卖后查看结果
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not end yet");

        return (highestBidder, highestBid);

    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // 允许非中标者撤回出价
    function withdrawBid() external {
        require(ended, "Auction has not ended yet");
        require(msg.sender != highestBidder, "Winner cannot withdraw bid");
        require(bids[msg.sender] > 0, "No bid to withdraw");
        require(!withdrawn[msg.sender], "Bid already withdrawn");
        
        withdrawn[msg.sender] = true;
        uint amount = bids[msg.sender];
        bids[msg.sender] = 0;
        
        // 转账给用户
        payable(msg.sender).transfer(amount);
    }
    
    // 接收以太币
    receive() external payable {}
    
    // 回退函数
    fallback() external payable {}
}