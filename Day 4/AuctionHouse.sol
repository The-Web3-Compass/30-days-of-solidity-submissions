// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AuctionHouse {
// auction parameters    
    address public seller;
    string public item;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;


// Return of lose to loosers
    mapping (address => uint) public pendingReturns;

// Auction state
    bool public ended;

//Events
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint _biddingTime,
        string memory _item
    ) {
        seller = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;

    }

//auction function
    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There already is a higher bid.");

    if (highestBid != 0){
        pendingReturns[highestBidder] += highestBid;
    }
    highestBidder = msg.sender;
    highestBid = msg.value;
    emit HighestBidIncreased(msg.sender, msg.value);
    }

// Retire fund is lose
function withdraw() external returns (bool) {
    uint amount = pendingReturns[msg.sender];
    if (amount > 0) {
        pendingReturns[msg.sender] = 0;

        if (!payable(msg.sender).send(amount)) {
            pendingReturns[msg.sender] = amount;
            return false;
        }
    }
    return true;
} 

function endAuction() external {
    require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
    require (!ended, "endAuction has already been called.");

    ended = true;
    emit AuctionEnded(highestBidder, highestBid);

    payable(seller).transfer(highestBid);
}
}
