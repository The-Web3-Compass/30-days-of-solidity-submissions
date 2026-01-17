//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

/* Create a basic auction!:
    Users can bid on an item
    After the highest bidder wins when time runs out. 
    use 'if/else' to decide who wins based on the highest bid 
    and track time using the blockchain's clock (`block.timestamp`). 
    This is like a simple version of eBay on the blockchain, showing how to control logic based on conditions and time.*/

contract AuctionHouse{
    //to store data about the action, including the item, the address of the people joined and set the time for bidding
    //these are public information
    string public item;
    address public owner;
    uint public biddingTime;

    //to store the person who is winning, but no one can know so use private here
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    //to know which person bids what price, and store the address of the bidder
    mapping(address=>uint)public bids;
    address[]public bidder;

    //to set up the auction process, clarify the owner,the item and the end time
    constructor(string memory _item, uint _biddingTime){
        owner=msg.sender; //store the current owner, is the one who sends the message
        item=_item;
        biddingTime = block.timestamp+_biddingTime; //in seconds
    }

    function bid(uint amount)external{
        //set the conditions of the function
        require(block.timestamp<biddingTime,"auction has already ended");
        require(amount>0,"bid amount must be positive");
        require(amount > bids[msg.sender],"new bid must be higher than the current one");

        //to track new bidders
        if(bids[msg.sender]==0){
            bidder.push(msg.sender);
        }
        //to store new bid
        bids[msg.sender]=amount;
        //to check if they're the winner
        if(amount>highestBid){
            highestBid= amount;
            highestBidder= msg.sender;
        }
    }

    //to end the auction
    function endAuction() external{
        require(block.timestamp>=biddingTime,"auction has not ended");
        require(!ended,"auction has already ended");

        ended=true;
    }

    //to retrieve the winner and their bid
    function getWinner()external view returns(address,uint){
        require(ended,"auction has not ended yet");
        return(highestBidder,highestBid);
    }

}