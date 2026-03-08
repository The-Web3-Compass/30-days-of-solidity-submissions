// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

contract AuctionHouse {

    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;
    address[] public bidders;

    constructor() {
        owner = msg.sender;
    }

    function getWinner() public view returns (address, uint) {
        require(ended, "Auction not yet ended.");
        return (highestBidder, highestBid);
    }

    function startAuction(string memory _item, uint _biddingTime) public {
        require(msg.sender == owner, "Only the owner can start the auction.");
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        ended = false;
    }

    function endAuction() public {
        require(msg.sender == owner, "Only the owner can end the auction.");
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        ended = true;
    }

    function bid() public payable {
        require(block.timestamp < auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There already is a higher bid.");

        if (highestBid != 0) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bidders.push(msg.sender);
    }
}