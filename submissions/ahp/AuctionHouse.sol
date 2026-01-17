//SPDX-License-indentifier: MIT

pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner;
    string[] public condidatenames;
    uint public auctionEndTime;
    constructor(uint _biddingTime) {
    owner = msg.sender;
    auctionEndTime = block.timestamp + _biddingTime;
    }


    mapping (string=>uint256) public highestbid;
    mapping(string => address) public highestBidder;
    function addcondidates(string memory _condidatenames) public {
        require(msg.sender == owner, "Only owner can add candidates");
        condidatenames.push(_condidatenames);
        highestbid[_condidatenames] = 0;
    }
    function addbid(string memory _condidatenames, uint256 _bid) public {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        if(highestbid[_condidatenames] < _bid){
            highestbid[_condidatenames] = _bid;
            highestBidder[_condidatenames] = msg.sender;
        }
    }
    function getHighestBid(string memory _condidatenames) public view returns(uint256){
        return highestbid[_condidatenames];
    }
    function endAuction(string memory _condidatenames) public view returns(address winner, uint amount){
        require(block.timestamp >= auctionEndTime, "Auction not yet ended");
        winner = highestBidder[_condidatenames];
        amount = highestbid[_condidatenames];

    }
}