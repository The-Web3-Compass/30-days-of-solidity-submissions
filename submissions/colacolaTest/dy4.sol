//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint256 public auctionTime;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended;

    mapping(address => uint256) bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionTime = block.timestamp + _biddingTime;
    }

    function bid(uint256 amount) public {
        require(block.timestamp < auctionTime, "Action has already ended." );
        require(amount > 0, "Invalid bid");
        require(amount > bids[msg.sender]);

        if(bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() public {
        require(block.timestamp >= auctionTime, "Auction hasn't ended yet.");
        require(!ended, "Action end has already called.");
        ended = true;
    }

    function getWinner() public view returns(address, uint256){
        require(ended, "Auction hasn't ended yet.");
        return(highestBidder, highestBid);
    }

    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }
}
