// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {

    address public owner;
    uint public treasure;

    mapping(address => uint) public allowance;
    mapping(address => bool) public hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addTreasure(uint _amount) public onlyOwner {
        treasure += _amount;
    }

    function approveWithdrawal(address _user, uint _amount) public onlyOwner {
        allowance[_user] = _amount;
    }

    function withdraw() public {
        require(allowance[msg.sender] > 0, "No allowance");
        require(!hasWithdrawn[msg.sender], "Already withdrawn");

        treasure -= allowance[msg.sender];
        hasWithdrawn[msg.sender] = true;
    }

    function ownerWithdraw(uint _amount) public onlyOwner {
        treasure -= _amount;
    }

    function resetWithdrawal(address _user) public onlyOwner {
        hasWithdrawn[_user] = false;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}