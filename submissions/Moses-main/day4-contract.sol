// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    // Create a basic auction! Users can bid on an item,
    // and the highest bidder wins when 
    // time runs out. You'll use 'if/else' 
    // to decide who wins based on the 
    // highest bid and track time 
    // using the blockchain's 
    // clock (block.timestamp). 
    // This is like a simple 
    // version of eBay on 
    // the blockchain, showing 
    // how to control logic 
    // based on conditions and time.



contract AuctionHouse {

    

    address payable public seller;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;
    
    uint256 public endBidding;
    bool public started;
    bool public ended;
    uint256 public startingBidPrice;

    
    // uint256 Time = block.timestamp;
    // uint256 public highestBid = 1;


    // let the seller be the deployer of the smart contract
    constructor() {
        seller = payable(msg.sender);
        startingBidPrice = 1 ether;
    }

    // start the bidding process
    function start() external {
        require(!started, "Started");
        require(msg.sender == seller, "Only seller can start the market");
        started = true;
        endBidding = block.timestamp + 5 minutes;
    }
    
  
    function bid() external payable {
        require(started, "Not started yet!");
        require(block.timestamp < endBidding, "Auction ended");
        require (msg.value >  highestBid, "There is already a higher bid");
        

        if(highestBidder != address(0)){
        // Refund the previous highest bidder
        bids[msg.sender] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    // Withdraw the bidden amount if the highest bidder
    function withdraw() external {
        uint256 amount = bids[msg.sender];
        require(amount > 0,"No funds to withdraw");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // function to get the highest bidder
   function getHighestBidder() public  view returns(address) {
    return highestBidder;
   }

   function end() external {
    require(started, "Not started yet!");
    require(block.timestamp >= endBidding, "Bidding Not Ended yet");
    require(!ended, "ended");

    ended = true;
    if (highestBidder != address(0)) {
        seller.transfer(highestBid);
    } 

   }


}


