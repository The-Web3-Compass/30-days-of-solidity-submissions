// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title AuctionHouse
 * @dev Create a basic auction!
 * Users can bid on an item, and the highest bidder wins when time runs out.
 * You'll use 'if/else' to decide who wins based on the highest bid and track time using the blockchain's clock (`block.timestamp`).
 * This is like a simple version of eBay on the blockchain, showing how to control logic based on conditions and time.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 4
 */
contract AuctionHouse {
    uint256 constant public duration = 30; // 30 seconds
    uint256 public endTs;
    uint256 private highestAmount = 0;
    address private highestBidder = address(0x00);

    constructor() {
        endTs = block.timestamp + duration;
    }

    function bid(uint256 amount) public {
        require(block.timestamp <= endTs, "cannot bid as auction is over");
        if (amount > highestAmount) {
            highestAmount = amount;
            highestBidder = msg.sender;
        }
    }

    function winner() public view returns(uint256 amount, address bidder) {
        require(block.timestamp > endTs, "winner is not ascertained until after auction is over");
        require(highestAmount > 0 && highestBidder != address(0x00), "auction received no valid bids before it closed");
        amount = highestAmount;
        bidder = highestBidder;
    }
}
