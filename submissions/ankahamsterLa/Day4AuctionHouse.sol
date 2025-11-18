// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

// Build an auction system where users can place bids for items and the system can determine the highest bidder who wins the items.


contract AuctionHouse{
    address public owner;//  There are someone who own the items for auction.
    string public item;// There are something which is used for auction.
    uint public auctionEndTime;// It is a timestamp which shows end time for auction.
    // Declaring state variables as private means their visibility is restricted to the current contract only.
    address private highestBidder;// There are someone who win the items for auction.
    uint private highestBid;// There is the highst bid for the items in auction.
    bool public ended;// It is the status to show whether the auction is ended.

    mapping(address=>uint) public bids;// Record the bidding users and their bidding cost.
    address[] public bidders;// Record the bidding users.

    // Initialize the auction for an item and a duration for bidding.
    // Constructor in contract is the part of initialization of some setting which can only execute in every contract deployment.
    // Functions can execute many times in every contract delpoyment.
    constructor(string memory _item,uint _biddingTime){
        owner=msg.sender;
        item=_item;
        auctionEndTime=block.timestamp+_biddingTime;

    }

    // Allow users to place bids.
    function bid(uint amount) external {
        // Syntax:require(condition,error message)
        // If the codes not satisfy the conditions, it would return the error message and stop the function running.
        require(block.timestamp<auctionEndTime,"Auction has already ended.");
        require(amount>0,"Bid amoount must be greater than zero");
        require(amount>bids[msg.sender],"New Bid must be higher than your current bid.");

        // The initial value of uint state variables  is zero.
        // This condition means that it is a new bidder.
        if(bids[msg.sender]==0){
            bidders.push(msg.sender);
        }

        bids[msg.sender]=amount;
        //Update the highest bid and bidder.
        if (amount>highestBid){
            highestBid=amount;
            highestBidder=msg.sender;
        }

    }

    // End the auction after the setting end time for auction.
    function endAuction() external{
        require(block.timestamp>=auctionEndTime,"Auction hasn't ended yet.");
        //"!ended" means "ended==false".
        require(!ended,"Auction end already called.");

        ended =true;

    }
    
    // Get a list of all bidders.
    function getAllBidders() external view returns(address[] memory){
        return bidders;
    }

    // Retrieve winner and their bid after auction ends.
    function getWinner() external view returns(address,uint){
        require(ended,"Auction has not ended yet.");
        return(highestBidder,highestBid);

    }




}
