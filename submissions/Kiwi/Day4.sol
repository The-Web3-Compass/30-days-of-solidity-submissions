// SPDX-License-Identifier:MIT

pragma solidity^0.8.0;

contract AuctionHouse{
    address public owner;
    uint public auctionEndTime;
    string item;
    uint private highestBid; // Highest bid is private,accessible via getWinner
    address private highestBidder;  //  winner is private,accessible via get
    bool public ended;

    mapping(address => uint) bids;
    address [] public bidders;

    constructor (string memory _item, uint _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    function bid(uint amount) external  {
         
         require(block.timestamp < auctionEndTime, "Auction has already ended.");
         require(amount > 0, "bid amount must be greater then zero.");
         require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

         if(bids[msg.sender ]== 0){
            bidders.push(msg.sender);
         }
           
        bids[msg.sender] = amount;

        if(amount > highestBid ) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }
     
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!ended,"Auction has already called.");

        ended =true;
    }

    function getAllBidders() external view returns (address[] memory) {

        return bidders;
    }
    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet");
        return (highestBidder, highestBid); // Return the winner and the highestBidder
    }


}