//SPDX-License-Identifier: MIT

pragma solidity^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    mapping (address => uint) public bids;
    address [] public bidders;

    constructor(string memory _item, uint biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid(uint256 amount) external{
        require (block.timestamp < auctionEndTime,"Auction expired");
        require (amount > 0, "Invalid bid");
        require (amount > bids[msg .sender], "Amount must be larger than the current bid");
        
    if (bids[msg.sender] == 0){
        bidders.push(msg.sender);
    }
         

    bids[msg.sender] = amount;
    if(amount > highestBid){
        highestBid = amount;
        highestBidder = msg.sender;
    }

    }

    function endAuction() external{
        require(block.timestamp > auctionEndTime, "Auction has not ended");
        require(!ended,"Auction already ended");
        ended = true;

    }     

    function getWinner() external view returns (address, uint256){
        require(ended, "Auction has not ended yet");
        return (highestBidder, highestBid);
    }
    
    function getAllBidders() external view returns(address[] memory) {
        return bidders;
    }     
}