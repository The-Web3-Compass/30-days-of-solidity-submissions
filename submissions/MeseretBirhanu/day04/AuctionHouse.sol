// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuctionHouse{

    uint256 public endtime;


    constructor(uint256 _auctionDuration){
        endtime = block.timestamp + (_auctionDuration * 1 days);
       }
      uint64[] public bidsamount;
      uint64 public winnerbid;
      mapping (uint64=>address) public bids;

      function bid(uint64 _amount) public{
        require(block.timestamp < endtime, "auction ended!");
        bids[_amount] = msg.sender;
        bidsamount.push(_amount);
      }
      function winner() public returns(address winnerAddress) {
        uint len = bidsamount.length;
        
        // gas not efficient tho 
        require(block.timestamp > endtime,"auction still going");
        for(uint i ; i<=len - 1;i++){
                if(bidsamount[i]>= winnerbid){
                    winnerbid = bidsamount[i];
                    return bids[winnerbid];
                }
            }
        
      }
    }