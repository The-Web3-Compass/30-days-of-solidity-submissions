// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    bool public ended;

    mapping(address => uint) public bids;
    address[] public bidders;

    event BidPlaced(address indexed bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(string memory _item, uint _biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > bids[msg.sender], "New bid must be higher than your current bid.");

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = msg.value;

        if (msg.value > highestBid) {
            highestBid = msg.value;
            highestBidder = msg.sender;
        }

        emit BidPlaced(msg.sender, msg.value);
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction already ended.");
        require(msg.sender == owner, "Only owner can end the auction.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }

    function withdraw() external {
        require(ended, "Auction not ended yet.");
        require(msg.sender != highestBidder, "Winner cannot withdraw here.");

        uint amount = bids[msg.sender];
        require(amount > 0, "Nothing to withdraw.");
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
