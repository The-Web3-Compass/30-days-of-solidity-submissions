// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;


contract AuctionHouse{

    address public owner;

    string public item;
     
    uint public auctionEndTime;

    address private highestBidder;

    uint private highestBid;

    bool public ended;

    mapping(address => uint) public bids;

    address[] public bidders;

    constructor(string memory _item,uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;

    }


    function bid(uint amount) public {
        require(block.timestamp < auctionEndTime, "This action already ended" );
        require(amount > 0, "Bid amount must be greater than zero");
        require(amount > bids[msg.sender] , "The new bid must be greater than your previous bid");

        if(bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }


        bids[msg.sender] = amount;

        if(amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }

    }

    function endAction() public {
        require(block.timestamp >= auctionEndTime, "This action already ended" );
        require(!ended, "Auction end already called.");
        ended = true;

    }

    // external: A function call from one contract to
    // another does not create its own transaction, 
    // it is a message call as part of the overall transaction.
    function getWiner() external view returns(address,uint){
        require(ended,"Action hasn't not ended yet" );
        return (highestBidder,highestBid);

    }

    function getAllBiders() external view returns(address[] memory){
        return bidders;
    }


}