// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint public treasureBalance;

    mapping(address => uint256) public approvedUsers;
    mapping(address => bool) public hasWithdrawn;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function depositTreasure() external payable onlyOwner {
        treasureBalance += msg.value;
    }


    function approveUser(address user, uint256 amount) public onlyOwner {
        require(amount <= treasureBalance, "Not enough treasure available");
        approvedUsers[user] = amount;
    }


    function resetWithdrawals(address user) external onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function withdraw() external {
        uint256 allowance = approvedUsers[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance");

        require(!hasWithdrawn[msg.sender], "Already withdrawn");

        require(allowance <= treasureBalance, "Not enough treasure in the chest");

        uint amount = treasureBalance / 10; 
        hasWithdrawn[msg.sender] = true;
        treasureBalance -= amount;

        payable(msg.sender).transfer(amount);
    }

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }
}
