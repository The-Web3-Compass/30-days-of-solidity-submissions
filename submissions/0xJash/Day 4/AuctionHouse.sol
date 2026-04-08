// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract AuctionHouse {

    address public owner;
    uint public highestBid;
    address public highestBidder;
    bool public ended;

    mapping (address => uint) public pendingReturns;

    struct Item {
        string name;
        uint endTime;
        uint startingBid;
    }

    Item public item;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    constructor (string memory _name, uint _duration, uint _startingBid) {
        highestBid = _startingBid;
        owner = msg.sender;
        item.name = _name;
        item.endTime = block.timestamp + _duration;
        item.startingBid = _startingBid;
    }

    function bid() public payable {
        require(block.timestamp < item.endTime, "Auction is over!");
        require(msg.value >= item.startingBid, "Below starting bid");
        require(msg.value > highestBid, "Bid too low");

        if(highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;       
    }

    function withdraw() external {
        require(pendingReturns[msg.sender] != 0, "No funds to withdraw!");

        uint amount = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;

        (bool s, ) = msg.sender.call{value: amount}("");
        require(s);
    }

    function endAuction() public onlyOwner {
        require(block.timestamp >= item.endTime, "Auction not ended yet!");
        require(!ended, "Auction already ended!");
        
        ended = true;

        if(highestBidder != address(0)) {
            (bool s, ) = owner.call{value: highestBid}("");
            require(s);
        }
    }
}