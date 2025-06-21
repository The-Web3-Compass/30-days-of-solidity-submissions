//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract AuctionHouse{

    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    bool public ended;
    uint256 public highestBid;

    mapping(address => uint256) public bids;
    address[] public bidders;


    constructor(string memory _item, uint256 _bidingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _bidingTime;

    }

    function bid(uint256 amount) external {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        require(amount > 0, "Bid amount must be graeter");
        require(amount > bids[msg.sender], "Bid must be higher than your previous");
        
        if (bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;
        if(amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external{
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet");
        require(!ended, "Auction ended already");
        ended = true;

    }

    function getwinner() external view returns(address, uint256){
        require(ended, "Auction hasent ended yet");
        return(highestBidder, highestBid);
    }

    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }
} 