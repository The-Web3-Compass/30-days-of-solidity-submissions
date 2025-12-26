// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {

    address public owner;
    string public itemName;
    string public itemDescription;
    uint public startingPrice;
    uint public auctionStartTime;
    uint public auctionEndTime;


    address public highestBidder;
    uint public highestBid;
    bool public auctionEnded;
    bool public auctionStarted;


    mapping(address => uint) public pendingReturns;

    event AuctionStarted(string itemName, uint startingPrice, uint endTime);
    event BidPlaced(address indexed bidder, uint amount, uint timestamp);
    event AuctionEnded(address winner, uint winningAmount);
    event WithdrawalMade(address indexed bidder, uint amount);

    constructor(
        string memory _itemName,
        string memory _itemDescription,
        uint _startingPrice,
        uint _auctionDurationMinutes
    ) {
        owner = msg.sender;
        itemName = _itemName;
        itemDescription = _itemDescription;
        startingPrice = _startingPrice;
        highestBid = _startingPrice;

        auctionStartTime = block.timestamp;
        auctionEndTime = block.timestamp + (_auctionDurationMinutes * 1 minutes);

        auctionStarted = true;
        auctionEnded = false;

        emit AuctionStarted(_itemName, _startingPrice, auctionEndTime);
    }

    function placeBid() external payable {
        if (!auctionStarted) {
            revert("Auction has not started yet");
        } else if (block.timestamp >= auctionEndTime) {
            revert("Auction has already ended");
        } else if (auctionEnded) {
            revert("Auction has been finalized");
        } else if (msg.value <= highestBid) {
            revert("Bid must be higher than current highest bid");
        } else if (msg.sender == owner) {
            revert("Owner cannot bid on their own auction");
        }

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value, block.timestamp);
    }

    function isAuctionExpired() public view returns (bool) {
        if (block.timestamp >= auctionEndTime) {
            return true;
        } else {
            return false;
        }
    }

    function endAuction() external {

        if (!auctionStarted) {
            revert("Auction never started");
        } else if (auctionEnded) {
            revert("Auction already ended");
        } else if (block.timestamp < auctionEndTime) {
            revert("Auction is still ongoing");
        }

        auctionEnded = true;


        if (highestBidder != address(0)) {
            payable(owner).transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid);
        } else {
            emit AuctionEnded(address(0), 0); 
        }
    }

    function withdraw() external {
        uint amount = pendingReturns[msg.sender];

        if (amount > 0) {

            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
            emit WithdrawalMade(msg.sender, amount);
        } else {
            revert("No funds available for withdrawal");
        }
    }

    function getAuctionStatus() external view returns (
        bool isActive,
        uint timeRemaining,
        address currentHighestBidder,
        uint currentHighestBid,
        bool hasEnded
    ) {
        bool active = auctionStarted && !auctionEnded && (block.timestamp < auctionEndTime);
        uint remaining = 0;

        if (block.timestamp < auctionEndTime) {
            remaining = auctionEndTime - block.timestamp;
        }

        return (active, remaining, highestBidder, highestBid, auctionEnded);
    }

    function getAuctionDetails() external view returns (
        string memory name,
        string memory description,
        uint startPrice,
        uint startTime,
        uint endTime,
        address auctionOwner
    ) {
        return (itemName, itemDescription, startingPrice, auctionStartTime, auctionEndTime, owner);
    }

    function extendAuction(uint additionalMinutes) external {
        if (msg.sender != owner) {
            revert("Only owner can extend auction");
        } else if (auctionEnded) {
            revert("Cannot extend ended auction");
        } else if (block.timestamp >= auctionEndTime) {
            revert("Cannot extend expired auction");
        }

        auctionEndTime += (additionalMinutes * 1 minutes);
    }

    function getTimeRemaining() external view returns (uint) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return auctionEndTime - block.timestamp;
        }
    }


    function getCurrentWinner() external view returns (address, uint) {
        if (highestBidder == address(0)) {
            return (address(0), 0);
        } else {
            return (highestBidder, highestBid);
        }
    }
}