//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {

    string public item;
    address public owner;
    uint public endTime;
    bool public isEnd;
    address[] public bidders;
    mapping(address => uint) public bids;
    
    uint private highestBid; // The highest bid is private, accessible by getWinner
    address private highestBidder; // The highest bidder is private, accessible by getWinner
    
    // Initialize the auction with an item and a duration.
    constructor (string memory _item, uint _biddingDuration) {
        item = _item;
        owner = msg.sender;
        endTime = block.timestamp + _biddingDuration;
    }

    // Allow users to bid(the bid amount should be greater than the highest bid so far).
    function bid(uint amount) external {
        //require(block.timestamp < endTime, "The auction is ended");
        require(isEnd, "The auction is ended.");
        require(amount > 0, "The bid amount should de greater than zero.");
        require(amount > highestBid, "Your bid amount is too low.");

        if(bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;
        highestBid = amount;
        highestBidder = msg.sender;
    }

    // End auction after the time has expired
    function endAuction() external {
        require(block.timestamp >= endTime, "The auction hasn't ended yet.");
        require(!isEnd, "The auction has already ended.");

        isEnd = true;
    }

    // Get winnder bidder and their bid after the auction has ended
    function getWinner() external view returns(address, uint) {
        require(isEnd, "The action hasn't ended yet.");
        return (highestBidder, highestBid);
    }

    // Get a list of all bidders
    function getBidders() external view returns(address[] memory) {
        return bidders;
    }

}