// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract AuctionHouse{
    address public owner;
    string public item;
    address private highestBidder;
    uint256 private highestBid;
    uint256 public auctionEndTime;
    bool public ended;
    mapping (address => uint256) public allBids;
    address[] public allBidders;
    constructor(string memory _item,uint _endtime){
        owner = msg.sender;
        item = _item;
        highestBid = 20;
        highestBidder = address(0);
        auctionEndTime = block.timestamp + _endtime; // Auction lasts for 3 days
        ended = false;
    }
    
    //external
    //外部函数是合约接口的一部分， 这意味着它们可以从其他合约和通过交易调用。
    //外部函数 f 不能被内部调用（即 f() 不起作用，但 this.f() 有效）。
    function bid(uint256 amount) external {
        require(block.timestamp<auctionEndTime,"Auction has already ended.");
        require(amount>0,"Bid amount must be greater than zero.");
        require(amount*100>highestBid*105,"New bid must be higher than highest bid for 1.05 times.");

        highestBid = amount;
        highestBidder = msg.sender;
        if(allBids[msg.sender] == 0){
            allBidders.push(msg.sender);
        }
        allBids[msg.sender] = amount;
    }

    function endAuction() external  {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");
        ended = true;
    }

    function getAllBidders() external view returns (address[] memory){
        return allBidders;
    }

    function getWinner() external view returns (address,uint256){
        require(ended,"Auction is still ongoing");
        require(allBidders.length>0,"There is no bidder");
        return (highestBidder,highestBid);
    }

}