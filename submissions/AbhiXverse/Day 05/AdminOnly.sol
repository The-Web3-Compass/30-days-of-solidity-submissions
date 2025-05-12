// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract AdminOnly {
 
    address public owner;                                    // address of the owner 
    uint256 public totaltreasure;                            // total treasure amount 

    mapping(address => uint256) public allowed;              // how much treasure each user allowed to take        
    mapping(address => bool) public alreadytaken;            // tracks if the user has already taken the treasure 

    constructor() { 
        owner = msg.sender;                                  // set the deployer as the owner 
    } 

    modifier admin() {
        require(owner == msg.sender, "only owner");          // only owner can call the function 
        _;
    }

    // function to add the trasure to the contract 
    function addtreasure() public payable admin {
        totaltreasure += msg.value;
    }

    // owner allows a specific user to get treasure 
    function allowUser(address user, uint256 amount) public admin {
        require( amount <= address(this).balance, "not enough treasure");
        allowed[user] = amount;
    }

    // function to get the trasure if allowed and havn't taken already 
    function gettreasure() public {
        require(allowed[msg.sender] > 0, "Not allowed to get treasure");
        require(!alreadytaken[msg.sender], "already get the treasure");
        uint256 amount = allowed[msg.sender];
        alreadytaken[msg.sender] = true;
        totaltreasure -= amount;
        payable(msg.sender).transfer(amount);
    }

    // function to check the current treasure balance 
    function checktreasureBalance() public view returns(uint256) {
        return address(this).balance;
    }

    // owner can reset a user's withdrawal status (let them withdraw again)
    function resertetTreasureStatus(address user) public admin {
        alreadytaken[user] = false;
    }
    
    // owner can transfer control of the treasure contract or chest to someone else
    function transferOwnership(address newOwner) public admin {
        require (newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
}
