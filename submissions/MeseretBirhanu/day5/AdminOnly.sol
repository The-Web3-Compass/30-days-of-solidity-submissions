// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TreasureChest {
    address public owner;
    uint256 public totalTreasure;

    mapping(address => uint256) public allowance;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function addTreasure(uint256 _amount) public onlyOwner {
        require(_amount > 0 , "amount must be greater than 0");
        totalTreasure += _amount;
    }

    function approveFriend(address _friend, uint256 _amount) public onlyOwner {
        allowance[_friend] = _amount;
    }

    function withdraw() public {
        uint256 amount = allowance[msg.sender];
        
        require(amount > 0, "No treasure for you");
        require(!hasWithdrawn[msg.sender], "Already took your share");
        require(totalTreasure >= amount, "bank is empty!");

        totalTreasure -= amount;
        hasWithdrawn[msg.sender] = true; 
    }

    function resetUser(address _user) public onlyOwner {
        hasWithdrawn[_user] = false;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
}