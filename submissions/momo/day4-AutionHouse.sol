// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutionHouse {
  address public owner;

  string public item;
  uint public startingPrice;
  uint public autionEndTime;

  address private highestBidder;
  uint private highestBid;

  

  mapping(adress => uint) bids;

  address[] public  bidders;

  bool pubic contractActive = true;

  event contractDisabled(address, amount);

  modifier(){
    require(contractActive，“Contract has closed.”);
    _;
  }
  
  construtor(string _item, uint bid_time )
  {
    owner = msg.sender;
    item = _item;
    autionEndTime = block.timestamp + bid_time;
  }

  function bid(uint _amount) external {
    require(autionEndTime > block.timestamp,"Aution has ended.");
    require(_amount>startingPrice, "The aution amount has greater than starting price.");
    require(bids[msg.sender] * 105 / 100 <= _amount, "Must greater than your last bid‘s 5%");
    

    if(bids[msg.sender] == 0){
      bidders.push(msg.sender)
    }
    bids[sender] = _amount;

    if(_amount > highestBid) {
      highestBid = _amount;
      highestBidder = msg.sender;
    }

    function endBid() external {
      require(block.timestamp >= autionEndTime);
    
      emit contractDisabled(highestBidder, highestBid );
      contractActive = false;
    }

    function getBidders() external view returns(address[] memory){
      return bidders;
    }    
  }
