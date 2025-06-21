// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleAuction {
    // Auction details
    address payable public owner;
    string public itemName;
    uint public auctionEndTime;
    
    // Auction state
    address public highestBidder;
    uint public highestBid;
    bool public ended;
    
    // Track bidder balances for refunds
    mapping(address => uint) public pendingReturns;
    
    // Events
    event AuctionStarted(string item, uint endTime);
    event NewHighestBid(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event Withdrawal(address bidder, uint amount);

    constructor(string memory _itemName, uint _biddingTime) {
        owner = payable(msg.sender);
        itemName = _itemName;
        auctionEndTime = block.timestamp + _biddingTime;
        emit AuctionStarted(_itemName, auctionEndTime);
    }
    
    /// @notice Place a bid on the auction
    function bid() public payable {
        // Check auction is still open
        require(block.timestamp < auctionEndTime, "Auction ended");
        // Check bid is higher than current highest
        require(msg.value > highestBid, "Bid too low");
        
        // If there was a previous bidder, record their refund
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        // Update auction state
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        emit NewHighestBid(msg.sender, msg.value);
    }
    
    /// @notice End the auction and send funds to owner
    function endAuction() public {
        // Only after auction end time
        require(block.timestamp >= auctionEndTime, "Auction not ended");
        // Only once
        require(!ended, "Auction already ended");
        
        // Mark as ended
        ended = true;
        
        // Transfer highest bid to owner
        owner.transfer(highestBid);
        
        emit AuctionEnded(highestBidder, highestBid);
    }
    
    /// @notice Withdraw funds if outbid
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // Reset refund before sending to prevent reentrancy
            pendingReturns[msg.sender] = 0;
            
            // Send funds
            payable(msg.sender).transfer(amount);
            
            emit Withdrawal(msg.sender, amount);
            return true;
        }
        return false;
    }
    
    /// @notice Get time remaining in auction
    function timeRemaining() public view returns (uint) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        }
        return auctionEndTime - block.timestamp;
    }
    
    /// @notice Get current auction state
    function getAuctionState() public view returns (
        string memory, 
        uint, 
        uint, 
        address, 
        uint, 
        bool
    ) {
        return (
            itemName,
            auctionEndTime,
            timeRemaining(),
            highestBidder,
            highestBid,
            ended
        );
    }
}
