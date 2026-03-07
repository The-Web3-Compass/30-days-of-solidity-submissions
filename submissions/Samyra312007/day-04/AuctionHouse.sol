//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

contract AuctionHouse{
    string[] public bidderNames;
    mapping(string => uint256) bidValue;
    uint256 public auctionEndTime;
    uint256 public highestBidderValue = 0;
    string public highestBidderName;

    constructor(){
        auctionEndTime = block.timestamp + 1 minutes;
    }

    function addBidders(string memory _bidderName) public {
        bidderNames.push(_bidderName);
        bidValue[_bidderName] = 0;
    }

    function getBidderNames() public view returns (string[] memory){
        return bidderNames;
    }

    function bid(uint256 _bidValue, string memory _bidderName) public {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        require(bidValue[_bidderName] >= 0, "Bidder is not registered");
        require(highestBidderValue < _bidValue, "Bid must be higher than the current bid");
        bidValue[_bidderName] += _bidValue;
        if(_bidValue > highestBidderValue){
            highestBidderValue = _bidValue;
            highestBidderName = _bidderName;
        }
    }

    function bidWinner() public view returns (string memory, uint256){
        require(block.timestamp >= auctionEndTime, "Auction not ended yet");
        return (highestBidderName, highestBidderValue);
    }
}