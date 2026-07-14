// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract AuctionHouse {
    string public item;
    uint256 private startingPrice;
    uint256 public endTimestamp;
    uint256 public highestBid;
    address public owner;

    constructor(uint256 _startingPrice, uint256 _endTimestamp) {
        owner = msg.sender;
        item = 'Macbook Pro M4 14"';
        startingPrice = _startingPrice;
        endTimestamp = _endTimestamp;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You're not the owner!");
        _;
    }

    function bid() external payable {
        require(block.timestamp < endTimestamp, "Auction has finished");
        require(
            msg.value >= checkMinimumBid(),
            "You must bid a higher amount!"
        );
        highestBid = msg.value;
    }

    function checkMinimumBid() public view returns (uint256 minimumBid) {
        // highestBid + (highestBid * 10) / 100
        // = highestBid * (1 + 10/100)
        // = highestBid * (110/100)
        minimumBid = (highestBid * 110) / 100; // highestBid + 10%

        if (minimumBid < startingPrice) {
            minimumBid = startingPrice;
        }
    }

    function withdraw() external onlyOwner {
        require(block.timestamp > endTimestamp, "Auction hasn't finished yet");
        (bool sent, ) = owner.call{value: highestBid}("");
        require(sent, "Unable to withdraw funds");
    }

    // To-do: Allow losing bids to be withdrawn
}
