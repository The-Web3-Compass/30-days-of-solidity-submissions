// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {

    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    uint public startPrice; 
    uint public constant MIN_BID_INCREMENT_PERCENTAGE = 5; 
    mapping(address => uint) public pendingReturns;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    
    constructor(string memory _item, uint _biddingTime, uint _startPrice) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        require(_startPrice > 0, "Starting price must be greater than 0.");
        startPrice = _startPrice;
    }
    
    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(msg.value > 0, "Bid amount must be greater than zero.");

        if (highestBidder == address(0)) {
            require(msg.value >= startPrice, "First bid must be >= starting price.");
        } else {
            uint requiredBid = highestBid + (highestBid * MIN_BID_INCREMENT_PERCENTAGE / 100);
            require(msg.value > requiredBid, "Bid must be at least 5% higher than the current highest bid.");
        }
        
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");
        ended = true;

        if (highestBidder != address(0)) {
            payable(owner).transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        }
    }

    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "You have no funds to withdraw.");

        pendingReturns[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    function getWinner() external view returns (address, uint) {
    require(ended, "Auction has not ended yet.");
    return (highestBidder, highestBid);
    }
}