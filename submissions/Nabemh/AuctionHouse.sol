// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {

    struct Item {
        uint256 id;
        uint256 deadline;
        mapping(address => uint256) bids;
        uint256 highestBid;
        address highestBidder;
        bool exists;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemCount;

    function createItem(uint256 _itemId, uint256 _duration) public {
        require(!items[_itemId].exists, "Item already exists");

        Item storage newItem = items[_itemId];
        newItem.id = _itemId;
        newItem.deadline = block.timestamp + _duration;
        newItem.highestBid = 0;
        newItem.highestBidder = address(0);
        newItem.exists = true;

        itemCount++;
    }

    function placeBid(uint256 _itemId, uint256 _bidAmount) public {
        require(items[_itemId].exists, "Item does not exist");
        Item storage currentItem = items[_itemId];

        require(block.timestamp < currentItem.deadline, "Auction has ended");
        require(_bidAmount > currentItem.highestBid, "Bid must be higher than the current highest");

        // Update bid mapping
        currentItem.bids[msg.sender] = _bidAmount;

        // Update highest bid and bidder
        currentItem.highestBid = _bidAmount;
        currentItem.highestBidder = msg.sender;
    }

    function getHighestBidder(uint256 _itemId) public view returns (address, uint256) {
        require(items[_itemId].exists, "Item does not exist");
        Item storage currentItem = items[_itemId];
        return (currentItem.highestBidder, currentItem.highestBid);
    }

    function getMyBid(uint256 _itemId) public view returns (uint256) {
        require(items[_itemId].exists, "Item does not exist");
        return items[_itemId].bids[msg.sender];
    }
}
