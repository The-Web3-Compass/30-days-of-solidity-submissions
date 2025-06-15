
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended;

    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor (string memory _item, uint256 _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp +  _biddingTime;
        }

    function bid(uint256 amount) external {
        require( block.timestamp < auctionEndTime, "Auction has already ended" );
        require ( amount > 0,"Bid amount must be greater than zero" );
        require ( amount > bids[msg.sender], "Bid must be higher than your previous bid" );


    if (bids[msg.sender]==0){
        bidders.push(msg.sender);
    }
        bids[msg.sender] =amount;
        if(amount > highestBid ){
            highestBid = amount;
            highestBidder = msg.sender;
        }

    }
}