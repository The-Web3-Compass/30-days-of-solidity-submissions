// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {

    address public seller;
    uint256 public auctionEndTime;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public startingPrice;
    
    mapping(address => uint256) public pendingReturns;

    constructor(uint256 _biddingTime, uint256 _startingPrice) {
        seller = msg.sender; 
        startingPrice = _startingPrice; 
        auctionEndTime = block.timestamp + _biddingTime; 
        highestBid = _startingPrice; 
    }

    function bid() public payable {

        require(block.timestamp <= auctionEndTime, "Auction has ended");
   
        require(msg.value > highestBid, "Bid must be higher than current highest bid");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
  
        highestBid = msg.value;
        highestBidder = msg.sender;
    }

    function endAuction() public {
  
        require(
            msg.sender == seller || block.timestamp > auctionEndTime,
            "Only seller can end auction before time"
        );
        
        if (highestBidder != address(0)) {
            payable(seller).transfer(highestBid);
        }
    }
    
    function withdraw() public {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        pendingReturns[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    function getAuctionInfo() public view returns (
        address,    // seller
        uint256,    // auctionEndTime
        uint256,    // highestBid
        address,    // highestBidder
        uint256     // startingPrice
    ) {
        return (
            seller,
            auctionEndTime,
            highestBid,
            highestBidder,
            startingPrice
        );
    }
}