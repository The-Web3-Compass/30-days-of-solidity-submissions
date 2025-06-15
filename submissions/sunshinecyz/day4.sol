// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract AuctionHouse{
    address public owner;
    string public item ;
    uint public EndTime;
    //不能让人随意修改查看
    uint private  highestbid;
    address private  highestbidder;
    mapping(address => uint) public bids;
    address[] public bidders;
    bool public end = false;
    //
    constructor(string memory _item,uint _biddingtime){
        owner = msg.sender;
        item = _item;
        EndTime = _biddingtime;
        }

    //用户出价
    function bid(uint amount) external  {
        //在拍卖时间内
        require(block.timestamp < EndTime,"Auction alerdy end");
        //价格必须大于上次出的价
        require(amount>0,"amount must bigger than 0");
        require(amount > bids[msg.sender],"amount must bigger than highbig");

        //如果为第一次出价，加入列表
        if(bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        //更新出价人出的价格
        bids[msg.sender] = amount;
        
        //如果出价大于当前最高价，更新最高出价人和最高价格
        if(amount > highestbid){
            highestbidder = msg.sender;
            highestbid = amount;
        }
    }
   
   //结束拍卖
    function endAuction() external {
        require(block.timestamp < EndTime,"auction hasn't ended");
        require(end == false);
        end = true;
    }

    //查看最后的赢家
    function getWinner() external view returns(address  ){
        require(end == true,"auction hasn't ended");
        return highestbidder;
    }

    //查看所有竞拍者
    function getbidders() public view returns(address[] memory){
        return bidders;
    }

}