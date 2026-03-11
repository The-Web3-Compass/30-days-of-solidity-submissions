// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

contract AuctionHouse{
    address public owner; //owner of the auction
    struct Auctions{
        
        string item;// item to ve auctioned
        address highestBidder;// address of the highestBidder
        uint highestBid;// the highestBidded amount
        uint auctionEndTime;// end of the auction
        bool ended;//to Be sure the vid has ended
        uint reservePrice;// starting price of the Auction item
        mapping(address => uint) bids;// the amount each address bidded
        address[] bidders;// an array of the Bidders address
    }

    mapping(uint => Auctions) public auctions; // the no of Auctions
    uint public auctionId;// The aunction identifier

    constructor(
        string memory _item,
        uint _reservePrice,
        uint _duration){
        owner = msg.sender;

        Auctions storage auction = auctions[auctionId];
        auction.item = _item;
        auction.reservePrice = _reservePrice;
        auction.auctionEndTime = block.timestamp + (_duration * 1 hours);

        auctionId++;
        }

    function CreateBid(
        uint _reservePrice,
        uint _duration,
        string memory _item
    ) external  {
        require(msg.sender == owner, "you are not the owner");
        Auctions storage auction = auctions[auctionId];
        auction.item = _item;
        auction.reservePrice = _reservePrice;
        auction.auctionEndTime = block.timestamp + (_duration * 1 hours);

        auctionId++;
    }

    function Bid(
        uint _amount,
        uint _auctionId
    ) external payable {
        Auctions storage auction = auctions[_auctionId];
        require(msg.value >= _amount, "Sent ETH must equal or greater thav bid amount");
        require(block.timestamp < auction.auctionEndTime, "Auction has ended");
        require(msg.value > auction.reservePrice, "bid must be greater than set Price");
        require(msg.value > auction.bids[msg.sender], "New bid must be higher than your previous bid");

        if(_amount > auction.highestBid) {
            auction.highestBid = msg.value;
            auction.highestBidder = msg.sender;
        }
        }
        function endAuction() external{
        Auctions storage auction = auctions[auctionId];
        require (block.timestamp >= auction.auctionEndTime, "Auction has not ended yet");
        require (!auction.ended, "Auction has ended");
        auction.ended = true;   
        }

        function getWinner(uint _auctionId) external returns(address, uint){
        Auctions storage auction = auctions[auctionId];
        auctionId = _auctionId;

        require(auction.ended, "Auction not ended");

        return (auction.highestBidder, auction.highestBid);
        }

          
        function withdraw() external{
        Auctions storage auction = auctions[auctionId];
         require (auction.ended, "auction has not ended");
         require (msg.sender != auction.highestBidder, "Winner cannot widraw");

         uint _amount = auction.bids[msg.sender];
            require(_amount > 0, "you cannot withdraw 0");

            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "Transfer failed"); 

    }
    
}