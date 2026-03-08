// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

contract AdminOnly {
    address public owner;
    uint256 public treasure;
    mapping(address => bool) public allowedUsers;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyAllowed {
        require(allowedUsers[msg.sender], "You are not allowed to call this function.");
        _;
    }

    function allow(address user) public onlyOwner {
        allowedUsers[user] = true;
    }

    function addTreasure() public payable onlyAllowed {
        treasure += msg.value;
    }

    function withdraw(uint256 amount) public onlyAllowed {
        require(amount <= treasure, "Insufficient funds.");
        treasure -= amount;
        payable(msg.sender).transfer(amount);
    }
}