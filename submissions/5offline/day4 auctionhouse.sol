//SPDX-License-Identifier:MIX
pragma solidity^0.8.0;

contract AuctionHouse{
    address public owner;
    string public item;
    mapping(address=>uint) public bids;
    address[] public bidders;

    uint public AuctionEndTime;
    bool public ended;
    address private highestbidder;
    uint private highestbid;

constructor (string memory _item, uint _biddingtime){
    owner=msg.sender;
    item=_item;
    AuctionEndTime=block.timestamp+ _biddingtime;
}
 function bid(uint amount)external{
    require(amount>0, "bid amount must be greater than zero.");
    require(amount>bids[msg.sender],"new bid must be higher than your current bid.");
    require(block.timestamp<AuctionEndTime, "auction has already ended.");

    if (bids[msg.sender]==0){
        bidders.push(msg.sender);
    }
    bids[msg.sender]=amount;

    if(amount>highestbid){
        highestbid=amount;
        highestbidder=msg.sender;
    }
 }

function endauction()external{
    require(block.timestamp>=AuctionEndTime, "auction has not ended yet.");
    require(!ended, "auction end already called!");
    ended =true;

}
function getwinner()external view returns(address,uint) {
    require(ended,"auction has not ended yet." );
    return(highestbidder,highestbid);

}
function getallthebidder()external view returns(address[]memory ){
    return bidders;
}



    


}
