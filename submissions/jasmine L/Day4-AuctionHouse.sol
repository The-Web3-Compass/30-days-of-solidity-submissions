// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner; // 任何人可以验证竞拍
    string public item; // 拍卖对象
    uint public actionEndTime; //拍卖结束时间
    address private highestBidder; //Why private?
    uint private highestBid; //最高出价
    bool public ended; //拍卖是否结束

    mapping (address => uint) public bids; //实时出价记录
    address[] public bidders; //出价者名单

    constructor(string memory _item, uint _actionEndTime){
        owner = msg.sender;
        item = _item;
        actionEndTime = block.timestamp + _actionEndTime;
        highestBid = 0;
        ended = false;
    }
    
    function bid(uint amount) external {
        require(block.timestamp < actionEndTime,"Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids [msg.sender], "New bid must be higher than your current bid.");
        if (bids[msg.sender]==0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;
        if(amount>highestBid){
            highestBidder = msg.sender;
        }

    }

    function endAuction() external {
        require(block.timestamp >= actionEndTime, "Auction has not yet ended.");
        require(!ended, "Auction has already been ended.");
        ended = true;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }
}

