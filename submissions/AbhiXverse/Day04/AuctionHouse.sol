// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;


contract AuctionHouse {

    address public owner;                      // who ceated the auction 
    address public highestBidder;              // who placed the highest bid
    uint256 public highestBid;                 // highest bid amount 
    uint256 public endTime;                    // auction end time 
    bool public auctionEnded;                  // auction status 

    // set the auction end time when the contract os deployed 
    constructor(uint256 _durationInSeconds) {
        owner = msg.sender;                                       // set the owner 
        endTime = block.timestamp + _durationInSeconds;           // set the auction duration time 
        auctionEnded = false;                                     // auction starts as active 
    }


    // function to place a bid 
    function bid() public payable {
        require(block.timestamp < endTime, "Auction still running");               // cannot able to bid after time up 
        require(msg.value > highestBid, "Bid too low");                            // bid value should be higher then the current bid 
       
        // this returns previous highest bid to the last bidder 
        if(highestBid > 0) {
            payable(highestBidder).transfer(highestBid);
        }
        
        // update highest bidder and higheest bid 
        highestBidder = msg.sender;                                               
        highestBid = msg.value;
    }

    // funcrtion to end the auction and sends funds to the owner 
    function endAuction() public {
        require(block.timestamp >= endTime, "Auction ended");
        require(owner == msg.sender, "Only owner cna end the auction");
        payable(owner).transfer(highestBid);
        auctionEnded = true;
    }

    // function to get the auction details
    function getAuctionDetails() public view returns(address _highestBidder, uint256 _highestBid, uint256 _timeLeft, bool _ended) {
        uint256 timeLeft = endTime > block.timestamp ? endTime - block.timestamp :0;
        bool ended = auctionEnded || block.timestamp >= endTime;
        return (highestBidder, highestBid, timeLeft, ended);
    }
}
