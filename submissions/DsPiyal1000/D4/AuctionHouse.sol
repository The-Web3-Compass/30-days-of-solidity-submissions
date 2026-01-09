// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AuctionHouse {
    // State variables
    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended;
    uint256 public startingPrice;
    uint256 public minBidIncrement; // Percentage in basis points (100 = 1%)

    // Mappings and arrays
    mapping(address => uint256) public bids;
    mapping(address => uint256) public pendingReturns;
    address[] public bidders;

    // Events
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);
    event BidWithdrawn(address indexed bidder, uint256 amount);

    // Custom errors for gas optimization
    error AuctionAlreadyEnded();
    error AuctionNotEnded();
    error BidTooLow();
    error BidNotHighEnough();
    error TransferFailed();
    error NotOwner();
    error AuctionStillActive();

    constructor(
        string memory _item, 
        uint256 _biddingTime, 
        uint256 _startingPrice, 
        uint256 _minBidIncrementPercent
    ) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        startingPrice = _startingPrice;
        minBidIncrement = _minBidIncrementPercent;
        highestBid = _startingPrice - 1; // Set just below starting price
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function bid() external payable {
        if (block.timestamp >= auctionEndTime) revert AuctionAlreadyEnded();
        if (ended) revert AuctionAlreadyEnded();
        if (msg.value < startingPrice) revert BidTooLow();

        uint256 newBidAmount = bids[msg.sender] + msg.value;
        
        // Check if this is the first bid or if it meets the minimum increment requirement
        if (newBidAmount <= highestBid) {
            uint256 minBidRequired = highestBid + (highestBid * minBidIncrement / 10000);
            if (newBidAmount < minBidRequired) revert BidNotHighEnough();
        }

        // Add bidder to array if first time bidding
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        
        // If user already has a bid, add it to their pending returns
        if (bids[msg.sender] > 0) {
            pendingReturns[msg.sender] += bids[msg.sender];
        }
        
        // Update bid amount
        bids[msg.sender] = msg.value;

        // Update highest bid if applicable
        if (msg.value > highestBid) {
            // Previous highest bidder can withdraw their bid
            if (highestBidder != address(0)) {
                pendingReturns[highestBidder] += highestBid;
            }
            highestBid = msg.value;
            highestBidder = msg.sender;
        }

        emit NewBid(msg.sender, msg.value);
    }

    function endAuction() external onlyOwner {
        if (block.timestamp < auctionEndTime) revert AuctionStillActive();
        if (ended) revert AuctionAlreadyEnded();
        
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function withdraw() external returns (bool success) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // Set to zero before sending to prevent re-entrancy attacks
            pendingReturns[msg.sender] = 0;
            
            (bool sent, ) = payable(msg.sender).call{value: amount}("");
            if (!sent) {
                // Restore the amount if send fails
                pendingReturns[msg.sender] = amount;
                revert TransferFailed();
            }
            
            emit BidWithdrawn(msg.sender, amount);
            return true;
        }
        return false;
    }

    function getWinner() external view returns (address, uint256) {
        if (!ended) revert AuctionNotEnded();
        return (highestBidder, highestBid);
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    function getPendingReturn(address bidder) external view returns (uint256) {
        return pendingReturns[bidder];
    }
}