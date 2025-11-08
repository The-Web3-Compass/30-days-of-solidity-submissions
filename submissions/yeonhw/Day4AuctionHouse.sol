// SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract AuctionHouse{
    address public owner;
    string public  item;
    uint256 public auctionEndTime;
    address private highestBidder; 
    uint256 private highestBid;  //将最高价和最高价竞拍者设为私有，不暴露获胜者
    bool public ended;

    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _biddingTime){ //构造函数，只运行一次
        owner = msg.sender;  //message即msg，全局变量，部署合约的人的地址
        item = _item;  //被拍卖东西的名称
        auctionEndTime = block.timestamp + _biddingTime;  //拍卖结束时的时间
    }

    function bid(uint256 amount) external{ //external表示可以从外部访问--拍卖环节
        require(block.timestamp < auctionEndTime, "Auction has already ended");
        require(amount > 0,"Bid amount must greater than zero");
        require(amount > bids[msg.sender],"Bid must be higher than your previous bid"); //是比自己之前的出价高还是比上一个人的出价高呢？
        if(bids[msg.sender] == 0){ 
            bidders.push(msg.sender);
        } //如果为新的竞标者，将这个bidder添加到数组中

        bids[msg.sender] = amount;

        if(amount > highestBid){  //如果是第一次出现的最高价，更新这个最高价及其出价者
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external{  //到了拍卖截止时间，结束拍卖
        require(block.timestamp >= auctionEndTime, "Action has not ended yet");
        require(!ended,"Auction end has already been called");
        ended = true; //使用bool来确保sth只发生过一次
    }

    function getWinner() external view returns (address, uint256){  //拍卖结束，选出获胜者
        require(ended, "Auction has not ended yet."); //确认拍卖已结束
        return(highestBidder, highestBid);  //返回最后的竞拍成功者和对应的最高价
    }

    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }

}
