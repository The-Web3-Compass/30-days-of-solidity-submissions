// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract auction {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address public highestBidder;
    uint256 public highestBid;
    bool public auctionEnded;

    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _duration) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _duration;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(msg.value > 0, "Bid must be more than 0");
        require(msg.value > highestBid, "Bid not higher than highest");

        if (highestBid > 0) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }
    }
 
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction not ended");
        require(!auctionEnded, "Auction already ended");
        require(msg.sender == owner, "Only owner can end");
        auctionEnded = true;
    }

    function getHighestBidder() public view returns (address, uint256) {
        require(auctionEnded, "Auction not ended");
        return (highestBidder, highestBid);
    }

    function getAllBidders() public view returns (address[] memory) {
        return bidders;
    }
}
