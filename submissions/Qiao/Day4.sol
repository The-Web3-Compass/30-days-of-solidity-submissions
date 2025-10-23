// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint public auctionEndTime;
    bool public ended;
    address[] public bidders;
    mapping(address => uint) public bids;

    address private highestBidder;
    uint private highestBid;

    uint public minIncr;
    uint public startPrice;

    constructor (string memory _item, uint _biddingTime, uint _startPrice, uint _minIncr) {
        owner = msg.sender;
        item = _item;
        startPrice = _startPrice;
        minIncr = _minIncr;
        auctionEndTime = block.timestamp + _biddingTime;
        ended = false;
    }

    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        require(amount > startPrice, "Bid doesn't meet the requirement of starting bid");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid");
        require(amount - bids[msg.sender] >= bids[msg.sender] * minIncr / 100, "New bid doesn't meet the requirement for bid increment");

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        
        bids[msg.sender]  = amount;
        if(amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender; 
        }
               
    }

    function withdrawBid() external {
        require(bids[msg.sender] > 0, "You haven't made a bid yet.");
        require(bids[msg.sender] != highestBid, "Winner cannot withdraw their bid.");
        bids[msg.sender] = 0;
        for (uint i = 0; i < bidders.length; i++) {
            if (bidders[i] == msg.sender) {
                bidders[i] = bidders[bidders.length-1];
                bidders.pop();
            }
        }
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");
        ended = true;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction hasn't ended yet.");
        return(highestBidder,highestBid);

    }
    
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }


}