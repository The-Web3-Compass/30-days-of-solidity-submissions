// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    //address是个数据类型，用来表明账户身份
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    //结束后才能看到via getWinner
    bool public ended;
    //这场拍卖现在是不是已经结束？
    //Solidity 中的布尔变量默认值是 false。然后当拍卖结束时，我们在函数里改成 true
    
    mapping (address => uint) public bids;
    address[] public bidders;


    //构造函数。只在合约部署那一刻执行一次，之后永远不会再被调用
    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    //小括号 ( ) —— 定义“要传进来的参数”,大括号 { } —— 写“要执行的代码”
    //owner 是内部生成的，不需要传入


    //拍卖中，用户主要执行的操作
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has aready ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        //如果这是msg.sender用户的首次出价，我们将他们添加到bidders数组中

        bids[msg.sender] = amount;
        //保持出价

        if (amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    //拍卖结束(
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet");
        require(!ended, "Auction end already called");
        //检查是否未结束，拍卖只能被结束一次
        ended = true;
        //把状态改成已结束
    }

    //查看所有拍卖人
    function getAllBidders() external view returns (address[] memory){
        return bidders;
    }

    //拍卖结束后查看信息
    function getWinner() external view returns (address, uint){
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
    //Solidity 中每个函数都是“独立入口”，不会自动继承前面函数的执行上下文。
    //require(ended) 在 getWinner() 里不是多余的。不想在拍卖结束前暴露获胜者


    }


