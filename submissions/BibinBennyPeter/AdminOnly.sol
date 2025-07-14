// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {

  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  modifier onlyAdmin() {
    require(admins[msg.sender]|| msg.sender == owner, "Access denied: you do not have permission to call this function");
    _;
  }

  mapping (address => bool) public admins;

  event DonationReceived(address indexed donor, uint256 amount);

  constructor () {
    owner = msg.sender;
    admins[msg.sender] = true;
  }

  function donate() public payable {
    require(msg.value > 0, "Donation must be greater than 0");
    emit DonationReceived(msg.sender, msg.value);
  }

  function withdraw(uint256 _amount) public onlyAdmin {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds to withdraw");
    (msg.sender).transfer(_amount);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "New owner cannot be the zero address");
    owner = newOwner;
    admins[newOwner] = true;
  }

  function provideAccess(address _user) public onlyOwner {
    require(_user != address(0), "Cannot provide access to the zero address");
    admins[_user] = true;
  }
}
