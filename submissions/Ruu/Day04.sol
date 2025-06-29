//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AuctionHouse{

    address public owner;
    string public item;
    uint256 public AuctionEndTime;
    address private HighestBidder;
    uint256 private HighestBid;
    bool public ended;

    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor(string memory _item_, uint256 _BiddingTime_){
        owner = msg.sender;
        item = _item_;
        AuctionEndTime = block.timestamp + _BiddingTime_;

    }

    function bid(uint256 amount) external {
        require( block.timestamp < AuctionEndTime, "Auction has already ended ");
        require( amount > 0, "Bid amount must be greater than zero");
        require( amount > bids[msg.sender], "Bid must be higher than your previous bid");

    if(bids[msg.sender] == 0){
        bidders.push(msg.sender);
    }

    bids[msg.sender] = amount;
    
    if(amount > HighestBid){
        HighestBid = amount;
        HighestBidder = msg.sender;

    }

    }

    function EndAuction() external{
        require(block.timestamp >= AuctionEndTime, "Auction has not ended yet");
        require(!ended, "Auction end has already been called");
        ended = true;

    }

    function GetAllBidders() external view returns (address[] memory){
        return bidders;

    }
}
