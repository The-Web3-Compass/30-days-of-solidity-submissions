// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract AuctionHouse{
    address public owner;
    string public item;
    uint public auctionEndtime;
    address private highestBidder;
    uint private highestbid;
    bool public ended; //布尔值，确保某事件只发生一次
    mapping(address => uint)public bids;
    address[] public bidders;
    //自动获取地址，输入物品名，持续时间
    constructor(string memory _item,uint _biddingtime){
        owner =msg.sender;
        item =_item;
        auctionEndtime = block.timestamp + _biddingtime;
    }
    //允许用户参加竞拍
    function bid(uint amount) external {
        require(block.timestamp < auctionEndtime,"auction has already ended.");
        require(amount > 0,"bid amount must be greater than zero.");
        require(amount > bids[msg.sender],"new bid must be higher than your current bid");

        //若为新bid，录入bidder地址数组
        if (bids[msg.sender] ==0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] =amount;
        //若新出价最高，更新价格和地址
        if(amount > highestbid){
            highestbid = amount;
            highestBidder = msg.sender;
        }
    }
    //超过截止时间，翻转提醒为true
    function endauction() external {
        require(block.timestamp >= auctionEndtime, "auction hasn't ended yet");
        require(!ended,"auction end already called");
        ended = true;
    }
    //获取所有竞拍者地址
    function getallbidders()external view returns (address[] memory){
        return bidders;
    }
    //
    function getwinner() external view returns(address,uint){
        require(ended,"auction has not ended yet.");
        return (highestBidder,highestbid);
    }
}
