/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    bool public ended;

    // NEW: Tracks ETH owed to people who were outbid
    mapping(address => uint256) public pendingReturns;

    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _durationInSeconds) {
        auctionEndTime = block.timestamp + _durationInSeconds;
    }

    // UPDATED: 'payable' allows this function to receive actual ETH
    // We removed the 'bidAmount' parameter because the EVM automatically 
    // knows how much ETH was sent via 'msg.value'
    function bid() public payable {
        require(block.timestamp <= auctionEndTime, "The auction has already ended!");

        // Control Flow: Check if the ETH sent is higher than the current highest bid
        if (msg.value > highestBid) {
            
            // If someone else was already the highest bidder, we now owe them a refund!
            if (highestBid != 0) {
                pendingReturns[highestBidder] += highestBid;
            }

            // Update the new winner's details
            highestBidder = msg.sender;
            highestBid = msg.value;
            
            emit HighestBidIncreased(msg.sender, msg.value);
        } else {
            // The bid wasn't high enough, so we revert. 
            // (Reverting automatically refunds the ETH they just tried to send!)
            revert("Bid is not high enough to win.");
        }
    }

    // NEW: The "Pull over Push" withdrawal pattern.
    // Outbid users call this to pull their ETH back out of the contract safely.
    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        
        if (amount > 0) {
            // SECURITY: We zero out their balance BEFORE sending the ETH
            // This prevents a famous hack called a "Reentrancy Attack"
            pendingReturns[msg.sender] = 0;
            
            // Send the ETH back to the user
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            
            // If the transfer fails, give them their pending balance back
            if (!success) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function endAuction() public {
        require(block.timestamp >= auctionEndTime, "The auction is still running.");
        require(!ended, "The auction has already been finalized.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        
        // In a complete marketplace, you would transfer the winning highestBid 
        // to the item's original seller right here!
    }
}