//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint public endTime;
    bool public endFlag;
    mapping(address => uint) public bids;
    address[] public bidders;
    uint private highestBid;
    address private highestBidder;

//构造函数 初始化拍卖会召开者，拍品以及拍卖会时长
    constructor(string memory _item,uint _auctionTime){
        owner = msg.sender;
        item = _item;
        endTime = block.timestamp + _auctionTime;
    }

    function bid(uint amount) external {
        require(block.timestamp < endTime,"Auction has already ended");
        require(amount > 0,"amount should > 0");
        require(amount > bids[msg.sender],"Your bid should > prious bid");

        if(bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        if(amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }

    }

    function endAuction() external {
        require(block.timestamp >= endTime,"Auction has not ended yet");
        require(!endFlag,"Auction end has already be called");
        endFlag = true;
    }

    function getWinner() external view returns(address,uint){
        require(endFlag,"Auction has not ended yet");
        return(highestBidder,highestBid);
    }

    function getAllBidder() public view returns(address[] memory){
        return bidders;
    }


}