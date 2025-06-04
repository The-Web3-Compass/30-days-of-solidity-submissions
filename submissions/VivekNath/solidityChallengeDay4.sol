// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Auction {
    struct Bid {
        address bidder;
        uint256 amount;
    }

    struct AuctionItem {
        string name;
        uint256 startPrice;
        uint256 minIncrement;
        uint256 auctionEndTimes;
        address highestBidder;
        uint256 highestBid;
        uint256 count;
        bool auctionEnded;
        mapping(uint256 => Bid) bids;
    }
    mapping(uint256 => AuctionItem) public auctionItems;
    uint256 nextId;

    function createAuction(
        string memory _name,
        uint256 _startPrice,
        uint256 _minIncrement,
        uint256 _auctionTime
    ) public {
        AuctionItem storage newItem = auctionItems[nextId];
        newItem.name = _name;
        newItem.startPrice = _startPrice;

        newItem.minIncrement = _minIncrement;
        newItem.auctionEndTimes = block.timestamp + _auctionTime;
        newItem.auctionEnded = false;
        newItem.count = 0;

        nextId++;
    }

    function bid(uint256 _auctionId) public payable {
        AuctionItem storage item = auctionItems[_auctionId];
        require(!item.auctionEnded, "Auction has ended");
        require(
            msg.value >= item.startPrice,
            "Bid must be higher then start price"
        );
        require(
            msg.value >= item.highestBid + item.minIncrement,
            "Bid must be higher than current highest bid"
        );
        Bid memory newBid;
        newBid.bidder = msg.sender;
        newBid.amount = msg.value;
        item.bids[item.count] = newBid;
        item.highestBidder = msg.sender;
        item.highestBid = msg.value;
        item.count++;
    }

    function endAuction(uint256 _auctionId) public {
        AuctionItem storage items = auctionItems[_auctionId];
        require(
            msg.sender == items.highestBidder,
            "Only highestBidder can end the auction"
        );
        require(!items.auctionEnded, "Auction has alredy ended");
        require(
            block.timestamp >= items.auctionEndTimes,
            "Auction time is not ended"
        );
        items.auctionEnded = true;
        payable(msg.sender).transfer(items.highestBid);
    }
}
