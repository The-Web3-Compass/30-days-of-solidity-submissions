// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
      
  string[] users = ["user1", "user2", "user3", "user4"];
  
  mapping (string => uint256) public userToBidValue;
  
  uint public deadline;
  string public highestBidder = users[0];
  uint256 public highestBid = 0;
 
    // deadline is set to 2 minutes
   constructor() {
        deadline = block.timestamp + 2 minutes;
    }
  
   
    function CalculateHighestBid (string memory _bidUser, uint256 _bidValue ) private {
        if(_bidValue > highestBid){
            highestBid = _bidValue;
            highestBidder = _bidUser;
        }
    }

   
    function bid(string memory _bidUser, uint256 _bidValue) public {
        require(block.timestamp <= deadline , "Your alloted time is over");

        require(_bidValue > highestBid, "There already is a higher or equal bid, Please bid higher");

        userToBidValue[_bidUser] = _bidValue;
        CalculateHighestBid(_bidUser, _bidValue );
    }

    function bidWinner() public view returns (string memory, uint256){
      return (highestBidder, highestBid);
    }
  
}

  

  
