// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AuctionHouse{
    //拍卖会要素 (immutable来修饰)
    address public immutable owner;
    string public item;
    uint256 public immutable startPrice;
    uint256 public immutable endTime;

    bool public isEnd;

    uint256 private  highestBid;
    address private  highestBidder;

    mapping(address=>uint) public bids;
    address[] public bidders;
    
    
    // 事件记录
    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 winningBid);

    //构造函数
    constructor(string memory _item,uint _biddingTime,uint256 _startPrice){
        owner=msg.sender;
        startPrice=_startPrice;
        item=_item;
        endTime=block.timestamp+_biddingTime;
    }

    //出价
    function bid(uint amount) external {
        require(block.timestamp<endTime,unicode"拍卖会已经结束");
        require(amount>startPrice,unicode"拍卖金额要大于起拍价");
        require(amount>bids[msg.sender],unicode"新标价要更高");

        //如果是第一次出价，记录地址
        if(bids[msg.sender]==0){
            bidders.push(msg.sender);
        }

        bids[msg.sender]=amount;

        // if(amount>highestBid){
        //     highestBid=amount;
        //     highestBidder=msg.sender;
        // }
        highestBid = amount;
        highestBidder = msg.sender;

        emit BidPlaced(msg.sender, amount);

    }
    //拍卖结束（仅限合约拥有者）
    function endAuction() external {
        require(msg.sender==owner, unicode"仅限拥有者结束拍卖");
        require(block.timestamp>=endTime,unicode"拍卖还未结束");
        require(!isEnd,unicode"拍卖已经结束");
        isEnd=true;

        emit AuctionEnded(highestBidder, highestBid);
    }
    //查看结果
    function getWinner () external view returns(address,uint256){
        require(isEnd,unicode"拍卖还未结束");
        return(highestBidder,highestBid);
    }
    //查看所有出价者
    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }
}