// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint public startPrice;
    uint public auctionEndTime;
    
    address private highestBider;
    uint private highestBid;

    bool public ended;
    uint256 public constant MINIMUM_INCREMENT = 500;
    
    mapping(address=>uint)public bids;
    address[] public bidders;

    constructor(string memory _item, uint _biddingTime,uint _startPrice){
        owner = msg.sender;
        item = _item;
        startPrice = _startPrice;
        highestBid = _startPrice;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");
        
        uint256 minBid = highestBid*(10000+MINIMUM_INCREMENT)/10000;
                
        require(amount>=minBid,"Bid must be at least 5% higher");
        
        if(bids[msg.sender]==0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        if(amount>highestBid){
            highestBid=amount;
            highestBider=msg.sender;
        }
    }

    function endAuction() external {
        require(block.timestamp>=auctionEndTime,"Auction hasn't ended yet");
        require(!ended,"Auction end already called");
        
        ended=true;
    }

    function getWinner()external view returns(address,uint){
        require(ended,"Auction has not ended yet");
        return (highestBider,highestBid);
    }

    function getAllBidders()external view returns(address[] memory){
        return bidders;
    }
}