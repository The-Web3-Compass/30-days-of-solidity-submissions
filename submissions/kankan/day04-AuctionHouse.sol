// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

contract ActionHouse {
    address public owner;// 拍卖所有者
    string public item; // 拍卖的物品
    uint public auctionEndTime; //拍卖结束时间，拍卖运行时
    address private highestBidder; //出价最高者地址
    uint private highestBid;//出价最高金额
    bool public ended; // 出价是否结束
    mapping(address => uint) public bids; // 谁出价，对应出价金额
    address[] public bidders;// 出过价的人

    // 初始化拍卖信息
    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // 拍卖竞价
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime,"Auction has already ended.");
        require(amount> 0,"Bid amount must be greater than zero");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");
        if(bids[msg.sender]==0){
            bidders.push(msg.sender);
        }
        bids[msg.sender] = amount;
        if(amount>highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    // 结束拍卖
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called");
        ended = true;
    }

    // 查看拍卖后信息
    function getWinner() external view returns (address,uint){
        require(ended,"Auction hasn't ended yet.");
        return (highestBidder,highestBid);
    }

    function getAllBidders() external view returns (address[] memory){
        return bidders;
    }

}