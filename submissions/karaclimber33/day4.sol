// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;//谁拍
    string public item;//拍什么
    uint256 public auctionEndTime;//什么时候结束
    uint256 private highestBid;//最高价是多少不显示，不然拍卖永无止境？
    address private highestBidder;//最高价用户地址
    bool public ended;//结束标识符

    mapping(address=>uint256) public bids;//用户投了多少钱
    address[] public bidders;//参与者名单

    //构造函数，部署合约时执行一次
    constructor(string memory _item,uint _auctionEndTime) {
        item=_item;
        auctionEndTime=block.timestamp+_auctionEndTime;//区块时间加上定时
        owner=msg.sender;
    }
    function bid(uint amount) external{
        require(block.timestamp<auctionEndTime,"Auction has ended");//拍卖结束)
        require(amount>0,"bid amount must be greater than zero.");
        require(amount>bids[msg.sender],"New bids must be higher than your current bids.");
        
        //第一次出价的用户加入参与者名单中
        if(bids[msg.sender]==0){
            bidders.push(msg.sender);

        }

        bids[msg.sender]=amount;

        //如果出价大于目前最高价
        if(amount>highestBid){
            highestBid=amount;
            highestBidder=msg.sender;
        }
    }
    //计时器
    function endAuction() external{
        require(block.timestamp>=auctionEndTime,"Auction has not ended yet.");
        require(!ended,"Auction end already calls.");//标识符已启动

        ended=true;
    }
    
    //参与者排行榜
    function getAllbidders() external view returns(address[] memory) {
        return bidders;
    }
    
    //揭晓最后赢家
    function getWinner() external view returns(address,uint){
        require(ended,"Auction has not ended yet.");
        return(highestBidder,highestBid);
    }

}