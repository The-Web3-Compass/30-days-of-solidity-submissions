// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint public auctionendtime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;
    mapping(address => uint) public bids;
    address[] public bidders;
    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionendtime = block.timestamp + _biddingTime;
    }
        
    function bid(uint amount) external{
        require(block.timestamp < auctionendtime, "Auction has ended"); //time should be second?
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > (bids[msg.sender] * 105)/100, "Bid is too low");
        if(bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }
        bids[msg.sender] = amount;
        if(amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        } 
    }

    function endAuction() external {
        require(block.timestamp >= auctionendtime, "Auction hasn't ended yet");
        require(!ended, "Auction end already called");
        ended = true;
    }
   
    function getWinner() external view returns(address, uint){
        require(ended, "Auction hasn't ended yet");
        return (highestBidder, highestBid);
    }

    function getAllBidders() external view returns(address[] memory) {
        return bidders;
    }

}