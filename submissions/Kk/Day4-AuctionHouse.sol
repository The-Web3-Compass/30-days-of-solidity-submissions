// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    //auction info
    address public owner;
    string public item;
    uint public auctionEndTime;

    //bidder info
    address private highestBidder;
    uint private highestBid;
    mapping(address => uint) public bids;
    address[] public bidders;

    //ending flag
    bool public ended;

    //constructor function only can be executed once when the contract is depolyed automatically
    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender;//msg.sender is a built-in global variable, it can be used directly without declaration in input parameters
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;//UNIX time, 3600S = 1HR
    }
    
    //place a bid
    function bid(uint amount) external{
        //require(conditional expression, "optional error message string");
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        //whether it is the first bid, add msg.sender address into bidders array
        if (bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        //update bids mapping
        bids[msg.sender] = amount;

        //update highest bidder & highestbid
        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    //ending the auction
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");
        ended = true;
    }

    //highestbid & highestbidder is visible after the auction
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }

    //get all bidders
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

}
