// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBid;
    uint256 private minimumAmount;
    bool public ended;
    bool public successful;
    mapping(address => uint256) public bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _biddingTime, uint256 _minimumAmount) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        minimumAmount = _minimumAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not admin");
        _;
    }

    function bid() external payable {
        require(!ended, "Auction has ended");
        require(msg.value > 0, "Bid amount must be greater than zero.");

        uint256 newBid = bids[msg.sender] + msg.value;

        require(newBid > bids[msg.sender], "New bid must be higher than your current bid.");

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = newBid;

        if (newBid > highestBid) {
            highestBid = newBid;
            highestBidder = msg.sender;
        }
    }

    function withdraw() external {
        require(ended, "Auction has not ended yet");

        if (successful) {
            require(msg.sender != highestBidder, "The winner cannot withdraw their funds");
        }

        uint256 amount = bids[msg.sender];

        require(amount > 0, "Has no funds to withdraw");

        bids[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet");
        require(!ended, "Auction end already called.");
        ended = true;

        successful = highestBid >= minimumAmount;
    }

    function getWinner() external view returns (address, uint256) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }

    function withdrawWinningBid() external onlyOwner {
        require(ended, "Auction has not ended yet");
        require(successful, "Auction was not successful");
        require(highestBid > 0, "Bid amount must be greater than zero");

        uint256 amount = highestBid;

        bids[highestBidder] = 0;
        highestBid = 0;

        (bool success,) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
    }
}
