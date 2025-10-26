// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;//Winner is private,accessible via viewWinner
    uint private highestBid;//Winner is private,accessible via viewWinner
    bool public ended;

    mapping (address => uint)public bids;
    address[] public bidders;

    //On-chain transaction operations (bidding, closing).
    event bidPlaced(address indexed bidder,uint amount);
    event auctionEnded(address winner,uint amount);
    event withDrawn(address bidder,uint amount);

    constructor(string memory _item,uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
        highestBid = 0;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime,"Auction has already ended.");
        require(msg.value > 0,"Bid amount must be bigger than zero.");
        require(msg.value > bids[msg.sender],"New bid must be higher than your current bid.");

        uint minRequiredBid = highestBid + (highestBid * 5 / 100);//最低加价5%
        require(msg.value >= minRequiredBid,"Bid must be at least 5% higher than current highest.");

        if (bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }

        bids[msg.sender] = msg.value;

        if (msg.value > highestBid){
            highestBid = msg.value;
            highestBidder = msg.sender;
        }

        emit bidPlaced(msg.sender, msg.value);
    }

    function withDraw() external {
        require(ended,"Auction not ended yet.");
        require(msg.sender != highestBidder,"Winner cannot withdraw.");
        uint amount = bids[msg.sender];
        require(amount > 0,"Nothing to withdraw.");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit withDrawn(msg.sender, amount);
    }

    function endAuction() external {
        require(msg.sender == owner,"Only owner can end the auction.");
        require(block.timestamp >= auctionEndTime,"Auction hasn't ended yet.");
        require(!ended,"Auction end already called.");

        ended = true;

        payable (owner).transfer(highestBid);

        emit auctionEnded(highestBidder, highestBid);
    }

    function getAllBidders()external view returns (address[] memory){
        return bidders;
    }

    function viewWinner() external view returns (address,uint){
        require(ended,"Auction has not ended yet.");
        return(highestBidder,highestBid);
    }
}
