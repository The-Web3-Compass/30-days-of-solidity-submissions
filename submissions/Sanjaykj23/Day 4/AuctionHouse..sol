// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract Auction{
    mapping (address=>uint) private Bidders;
    address[] private BiddAddress;
    uint time;
    address owner;
    constructor(){
        time=block.timestamp;
        owner=msg.sender;
    }
    function Bid(uint amt)public{
        require(block.timestamp<=time+120,"Auction was Ended!");
        require(Bidders[msg.sender]==0);
        Bidders[msg.sender]=amt;
        BiddAddress.push(msg.sender);
    }
    function findHighestBid()public view returns(address,uint){
        uint bidAmt=0;
        address bidAddr;
        for(uint i=0;i<BiddAddress.length;i++){
            if(Bidders[BiddAddress[i]]>bidAmt){
                bidAmt=Bidders[BiddAddress[i]];
                bidAddr=BiddAddress[i];
            }
        }
        return (bidAddr,bidAmt);
    }
}