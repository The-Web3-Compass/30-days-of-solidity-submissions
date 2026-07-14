//SPDX-License-Identifier：MIT

pragma solidity ^0.8.0;

contract AuctionHouse{

   address public Owner;
   string public Item;
   uint256 public AuctionEndTime;
   address private HighestBidder;
   uint256 private HighestBid;
   bool public Ended;

   mapping (address => uint256) public Bids;
   address[] public Bidders;

   constructor(string memory _item, uint256 _biddingtime){
     Owner = msg.sender;
     Item = _item;
     AuctionEndTime = block.timestamp + _biddingtime;
   }
   
   function Bid(uint256 Amount) external{
     require(block.timestamp < AuctionEndTime,"Auction has already ended");
     require( Amount > 0,"Bid amount greater than zero");
     require( Amount > Bids[msg.sender], "Bid amount must be higher than your previous bid");

     if(Bids[msg.sender] == 0){
        Bidders.push(msg.sender);
     }

     Bids[msg.sender] = Amount;
     if (Amount > HighestBid){
        HighestBid = Amount;
        HighestBidder = msg.sender;
     }
   }

   function EndAuction() external{
     require(block.timestamp >= AuctionEndTime,"Auction has not ended yet");
     require(!Ended,"Auction end has already been called");
       Ended = true;
   }

   function GetWinner() external view returns (address,uint256){
    require(Ended,"Auction hasn't ended yet");
    return(HighestBidder,HighestBid);
   }

   function GetAllBidders() external view returns(address[] memory){
    return Bidders;
   }

}
