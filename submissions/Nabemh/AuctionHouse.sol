// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract auctionHouse {

    struct Item {
        uint[] id;
        uint256 deadline;
        uint[] bids;
        address[] bidders;
        uint256 highestBid;
        address highestBidder;
    }

    Item[] public items;

    function createItem(uint256 _id, uint256 _deadline) public {
        Item storage newItem = items.push();
        newItem.id.push(_id);
        newItem.deadline = block.timestamp + _deadline;
        newItem.highestBid = 0;
    }

    function placeBid(uint256 _i, uint256 bid) public {
        require(_i < items.length, "Item does not exist");        
        Item storage currentItem = items[_i];

        require(block.timestamp < currentItem.deadline, "Auction is over!");

        currentItem.bids.push(bid);
        currentItem.bidders.push(msg.sender);

        if (bid > currentItem.highestBid) {
            currentItem.highestBid = bid;
            currentItem.highestBidder = msg.sender;
        }
    }

    function getHighestBidder(uint256 _i) public view returns (address, uint256) {
        Item storage currentItem = items[_i];
        return (currentItem.highestBidder, currentItem.highestBid);
    }
}
