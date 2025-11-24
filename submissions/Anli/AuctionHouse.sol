//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AuctionHouse{
    /*思路：
    1. 定义：Owner, 出价人Bidder[]，item, starttime, bool ended, bidding time,Mapping出价bid,HigestBid, HighestBidder
    2.初始化合约，输入基础信息：谁是拍卖人，拍卖什么，拍卖多久
    3.进行出价的函数，验证时间，验证价格>0,且比上一次出价人的自己的价格高;
    录入本次出价；
    如果是最高的就录入为当前winner
    4.结束auction
    5. 确保auction已经结束，ShowBidder&Bid
    */
    address public owner; //address：一种表示以太坊地址（钱包地址）的变量类型
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended; //bool：只会为true/false，用来判断真伪，初始默认为false

    mapping(address => uint256) bids;
    address[] private bidders;

    constructor(string memory _item, uint256 _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid(uint256 amount) external {//external: 只能从外部调用，不能从内部调用，相比public比较节省gas。如果你只打算让别人从外部调用（比如用户出价、投票、转账），推荐用 external。
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid must be greater than zero!");
        require(amount > bids[msg.sender], "Bid must be higher than your previous bid!");
    
        if (bids[msg.sender] == 0){
        bidders.push(msg.sender);//push
    }

        bids[msg.sender] = amount;

        if (amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }

    }

    function endAuction() external {
        require (block.timestamp > auctionEndTime, "Auction hasn't ended yet!");
        require (!ended, "Auction end already called."); //!ended 是逻辑“非”，意思是“拍卖还没有结束”；如果不保证仅结束一次，拍卖结束后，任何人都可以再调用 endAuction(），合约可能重复做清算、转账、事件触发等重要操作，可能被滥用或攻击
        ended = true;
    }

    function getWinner() external view returns(address, uint256){
        require (ended, "Auction has not ended yet"); 
        return (highestBidder, highestBid); //合起来return，不能拆开写
    }

    function getBidders() external view returns(address[] memory){ //只有“引用类型”（比如 string、bytes、数组、结构体等）需要加 memory，address不需要加
        require (ended, "Auction has not ended yet!");
        return bidders;
    }
}