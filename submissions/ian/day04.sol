//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
contract sell{
    string public item;
    address public owner;
    uint public time;
    address private highestBidder;
    uint private highestprice;
    bool public ended;
     
     mapping(address=>uint)public bids;
     address []public bidders;
     constructor(string memory _item, uint _biddingTime){
       owner=msg.sender;
       item = _item;
       time =block.timestamp + _biddingTime;
}
      function bid(uint amount)external{
       require(block.timestamp < time , "Auction has already ended.");
       require(amount > 0 , "Bid must be greater than zero");
       require(amount > bids[msg.sender] , "New bid must be higher than your current bid");
        if (bids[msg.sender]==0){

            bidders.push(msg.sender);
        }
        bids[msg.sender] = amount ;
        if (amount  > highestprice){
            highestprice=amount;
            highestBidder=msg.sender;

        
        }
}
        function endAuction ()external{
            require(block.timestamp > time,"Auction hasn't ended yet.");
            require(!ended,"Auction end already called.");
            ended=true;}
            function getAllbidders () external view returns(address[]memory){
                return bidders;
            }



        
        function getwinners() external view returns(address , uint){
            require(ended, "Auction has not ended yet.");
            return (highestBidder,highestprice);
        }



      








}

