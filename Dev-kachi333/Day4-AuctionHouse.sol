// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Auction {

    address  public  Owner;
    string public  Item;
    uint256  public AuctionandTime;

    address private highestBidder;
    uint256 private  highestBid;

    bool public ended;
    mapping (address=>uint256) public bids;
     address[ ] public  bidders;

     constructor (string memory _Item, uint256 _biddingTime) {
        Owner=msg.sender;
        Item = _Item;
        AuctionandTime  = block.timestamp+_biddingTime;



     }

     function bid( uint256 amount) external {
        require(block.timestamp >AuctionandTime,"Auction already ended ");
        require(amount  > 0,"Bid amount is greater than zero");
        require(amount> bids [msg.sender],"Bid must be higher than your previous");

        if (bids [msg.sender]==0){

            bidders.push(msg.sender);
        }
        bids [msg.sender]=amount;
        if (amount >highestBid) {
            highestBid= amount;
            highestBidder=msg.sender;
        }

        

        }



        function endAuction () external {
            require(block.timestamp>=AuctionandTime," Auction has not endedyet");
            require(ended,"Auction end has already been called");
            ended =true;

        }

        function getwinner ()  external  view returns  ( address, uint256) {
            require(ended,"Auction has not ended");
            return (highestBidder,highestBid);


        }

        function getAllBidders () external  view  returns (address [] memory) {
            return  bidders;
        }

        
     }


