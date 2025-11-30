// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
 /*
    Create a basic auction! 
    Users can bid on an item, and the highest bidder wins when time runs out. 
    You'll use 'if/else' to decide who wins based on the highest bid and track time 
    using the blockchain's clock (`block.timestamp`). 
    This is like a simple version of eBay on the blockchain, showing how to control logic based on conditions and time. 
 */

contract AuctionHouse{
    
    address public owner;
    string public item;
    bool public ended;
    uint public auctionEndTime;

    address private highestBidder;
    uint private highestBid;
    
    address[] bidders;
    mapping(address=> uint) public bids; 

    constructor(string memory _item, uint256 _biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        ended = false;
        highestBid = 0;
    }

    function bid(uint256 _amount ) external {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        require(_amount > 0, "Bid must be greater than zero");
        require(_amount > highestBid, "Bid must be greater than highest bid");
        require(!ended, "Auction already ended");
        //If there are previous bidders
        if ( bidders.length > 0){
            //Refund the previous bidder
            bids[highestBidder] = highestBid;
        } 
        highestBidder = msg.sender; 
        highestBid = _amount;
        bidders.push(msg.sender);
    }
    
    function endAuction() external {
        require(block.timestamp <= auctionEndTime, " Auction has not ended yet");
        require(!ended, "Auction end has been called");
        ended = true;
    }
    function getWinner() external view returns (address, uint256) {
        return (highestBidder, highestBid);
    }
    function getBidders() external view returns (address[] memory) {
        return bidders;
    }

}