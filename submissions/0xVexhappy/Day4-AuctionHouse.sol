// SPDX-License-Identifier: MIT
// @author 0xVexhappy

pragma solidity ^0.8.31;

contract AuctionHouse{
    address public owner;           // Who created the auction
    string public item;             // What's being auctioned
    uint public auctionEndTime;     // When bidding stops
    address private highestBidder;  // Current winner
    uint private highestBid;        // Winning bid amount
    bool public ended;              // Has auction been finalized?
    mapping(address => uint) public bids;  // Everyone's current bid
    address[] public bidders;       // List of all bidders
    mapping(address => bool) isAdded; // Checks whether bidder already added

    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
        item = _item;
    }

    function bid(uint _bid) external  {
        require(block.timestamp < auctionEndTime, "Auction Ended!");
        require(_bid > 0, "Bid amount must be greater than 0.");
        require(_bid > bids[msg.sender], "New bid must be higher than your current bid.");

        if (isAdded[msg.sender] == false){
            bidders.push(msg.sender);
            isAdded[msg.sender] = true;
        }

        bids[msg.sender] = _bid;

        if (_bid > highestBid){
            highestBid = _bid;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet!");
        require(!ended, "Auction end already called!");
        ended = true;
    }

    function getWinner() external view returns(address, uint){
        require(ended, "Auction hasn't ended yet.");
        return (highestBidder, highestBid);
    }

    }
