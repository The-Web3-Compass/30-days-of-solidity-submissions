// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PollStation{
    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended;

    mapping (address => uint256) public bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _biddingtime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingtime;
    }

    function bid(uint256 amount) external {
        require(block.timestamp < auctionEndTime,"Auction has ended!");
        require(amount > 0,"No money?get out");
        require(amount > bids[msg.sender],"You can't bid less than your previous bid!");

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
        require (block.timestamp >= auctionEndTime,"Auction has not ended yet");
        require (!ended,"Auction end has already been called");
        ended = true;
    }

    function getWinner() external view returns(address,uint256) {
        require (ended == true,"Just wait for it...");
        return (highestBidder,highestBid);
    }

    function getAllBidders() external view returns (address[] memory){
        return bidders;
    }
    
    function timeLeft() external view returns (uint256) {
    if (block.timestamp >= auctionEndTime || ended) {
        return 0;
    }
    return auctionEndTime - block.timestamp;
}
}
