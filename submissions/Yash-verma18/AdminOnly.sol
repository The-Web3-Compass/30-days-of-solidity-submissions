// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {

    address public owner;
    mapping(address => bool) public isApproved;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function approveUser(address _user) public onlyOwner {
        isApproved[_user] = true;
    }


  function withdrawTreasure() public returns (string memory) {
     require(isApproved[msg.sender], "YOU ARE NOT approved FOR withdrawals"); 
     
     require(!hasWithdrawn[msg.sender], "YOU already withdraw once, not allowed second time"); 
     
     require(address(this).balance >= 0.5 ether, "Insufficient treasure");
     hasWithdrawn[msg.sender] = true;
     payable(msg.sender).transfer(0.5 ether); 

     return "You are allowed to withdraw";
  }

  receive() external payable {}

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function resetWithdrawal(address _user) onlyOwner public {
    require(hasWithdrawn[_user], "User never withdrawn yet");
    hasWithdrawn[_user] = false;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "New owner can't be zero address");
    owner = _newOwner;
  }

}