//SPDX-License-Identifier:MIT

pragma solidity ^0.8.8;

contract AuctionHouse{

    address public owner;
    string public items;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBids;
    bool public Ended;

    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor(string memory _items, uint256 _biddingTime){

        owner = msg.sender;
        items = _items;
        auctionEndTime = block.timestamp + _biddingTime;


    }

    function bid(uint256 amount) external{

        require(block.timestamp > auctionEndTime, "Auction is already ended");
        require(amount > 0, "bid must be more than zero");
        require(amount > bids[msg.sender] ,"bid must be higer than the previous");

    if(bids[msg.sender] == 0){
    bidders.push(msg.sender);
        }

    bids[msg.sender] = amount;
    if(amount > highestBids){
    highestBids = amount;
    highestBidder = msg.sender;


    }

    }

    function endAuction() external{
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet");
        require(!Ended, "Auction is already ended");
        Ended = true;

    }

    function getWinner() external view returns(address,uint256){
        require(Ended, "Auction has not ended yet");
        return(highestBidder, highestBids);
    }

    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }



}
