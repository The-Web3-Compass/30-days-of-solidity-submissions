// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AuctionHouse{

    address public owner;
    string public item;
    uint256 public actionEndTime;
    //买方信息：过程私密
    address private highestBidder;
    uint256 private highestBid;
    //拍卖过程信息：拍卖是否结束、竞价者列表
    bool public ended;
    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _biddingTime){

        owner = msg.sender;
        item = _item;
        actionEndTime = block.timestamp + _biddingTime;

    }

    function bid(uint256 amount) external{
        //当前时间<终止时间 ｜ 叫价大于0 ｜ 下次叫价大于当前叫价
        require(block.timestamp < actionEndTime, "Auction has already ended.");
        require(amount > 0 && amount > bids[msg.sender], "Bid amount must be greater than zero and the current bid.");

        if(amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }

        //把竞价者都记录在名单bidders
        bids[msg.sender] = amount;
        bidders.push(msg.sender);
    }

    function endAuction() external{
        require(block.timestamp >= actionEndTime, "Auction has not ended yet.");
        ended = true;
    }

    function getWinner() external view returns(address, uint256){
        require(ended, "Auction has not ended yet.");
        return(highestBidder, highestBid);
    }

}