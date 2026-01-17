// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    uint256 public auctionStartTime;
    uint256 public auctionDuration = 5 minutes;
    bool public auctionEnded;

    address public highestBidder;
    uint public highestBid;

    struct User {
        string userName;
        uint assetBid;
        address userAddress;
    }

    struct Item {
        string itemName;
        uint itemPrice;
    }
     
    User[] public users;
    Item[] public items;

    constructor() {
        auctionStartTime = block.timestamp;
    }

    modifier auctionOngoing() {
        require(!auctionEnded, "Auction has ended.");
        require(block.timestamp <= auctionStartTime + auctionDuration, "Auction time is over.");
        _;
    }

    function registerUser(string calldata userName, uint assetBid) external auctionOngoing {
        users.push(User(userName, assetBid, msg.sender));

        if (assetBid > highestBid) {
            highestBid = assetBid;
            highestBidder = msg.sender;
        }
    }

    function registerItem(string calldata itemName, uint itemPrice) external auctionOngoing {
        items.push(Item(itemName, itemPrice));
    }

    function getHighestBidder() external view returns (string memory name, uint bid, address bidder) {
        return (getUsernameByAddress(highestBidder), highestBid, highestBidder);
    }

    function finalizeAuction() external {
        require(!auctionEnded, "Auction already finalized.");
        require(block.timestamp > auctionStartTime + auctionDuration, "Auction is still ongoing.");
        
        auctionEnded = true;
    }

    function getUsernameByAddress(address userAddr) internal view returns (string memory) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i].userAddress == userAddr) {
                return users[i].userName;
            }
        }
        return "";
    }
}
