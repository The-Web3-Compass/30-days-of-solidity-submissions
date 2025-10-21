// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint256 public auctionEndTime;
    uint256 public startingPrice;
    uint256 public minimumIncrement;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended;
    
    mapping(address => uint256) public bids;
    mapping(address => uint256) public pendingReturns;
    address[] public bidders;
    
    event BidPlaced(address indexed bidder, uint256 amount, bool isNewHighest);
    event AuctionEnded(address winner, uint256 winningBid);
    event BidWithdrawn(address indexed bidder, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier auctionActive() {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        require(!ended, "Auction has been finalized");
        _;
    }
    
    modifier auctionFinished() {
        require(ended, "Auction has not ended yet");
        _;
    }
    
    constructor(string memory _item, uint256 _biddingTime, uint256 _startingPrice, uint256 _minimumIncrement) {
        require(_biddingTime > 0, "Bidding time must be greater than zero");
        require(bytes(_item).length > 0, "Item description cannot be empty");
        require(_startingPrice > 0, "Starting price must be greater than zero");
        require(_minimumIncrement > 0 && _minimumIncrement <= 50, "Minimum increment must be between 1-50%");
        
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        startingPrice = _startingPrice;
        minimumIncrement = _minimumIncrement;
    }
    
    function bid(uint256 amount) external auctionActive {
        require(amount >= startingPrice, "Bid must be at least the starting price");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid");
        require(msg.sender != owner, "Owner cannot bid on their own auction");
        
        if (highestBid > 0) {
            uint256 minimumRequiredBid = highestBid + (highestBid * minimumIncrement / 100);
            require(amount >= minimumRequiredBid, "Bid must meet minimum increment requirement");
        }
        
        if (bids[msg.sender] > 0) {
            pendingReturns[msg.sender] += bids[msg.sender];
        }
        
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
        
        bids[msg.sender] = amount;
        bool isNewHighest = false;
        
        if (amount > highestBid) {
            if (highestBidder != address(0)) {
                pendingReturns[highestBidder] += highestBid;
            }
            
            highestBid = amount;
            highestBidder = msg.sender;
            isNewHighest = true;
        }
        
        emit BidPlaced(msg.sender, amount, isNewHighest);
    }
    
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction time has not expired yet");
        require(!ended, "Auction has already been ended");
        
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }
    
    function getWinner() external view auctionFinished returns (address winner, uint256 winningBid) {
        return (highestBidder, highestBid);
    }
    
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }
    
    function withdraw() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds available for withdrawal");
        
        pendingReturns[msg.sender] = 0;
        
        emit BidWithdrawn(msg.sender, amount);
        
        return true;
    }
    
    function getPendingReturn(address bidder) external view returns (uint256) {
        return pendingReturns[bidder];
    }
    
    function getMinimumBid() external view returns (uint256) {
        if (highestBid == 0) {
            return startingPrice;
        }
        return highestBid + (highestBid * minimumIncrement / 100);
    }
    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        }
        return auctionEndTime - block.timestamp;
    }
    
    function getBidCount() external view returns (uint256) {
        return bidders.length;
    }
    
    function getCurrentHighestBid() external view returns (uint256) {
        return highestBid;
    }
    
    function isAuctionActive() external view returns (bool) {
        return block.timestamp < auctionEndTime && !ended;
    }
    
}