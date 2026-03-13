// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawalAllowance;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Access denied: Only the owner can perform this action"
        );
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    function approveWithdrawal(
        address recipient,
        uint256 amount
    ) public onlyOwner {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            require(
                amount <= treasureAmount,
                "Not enough treasury available for this action."
            );
            treasureAmount -= amount;
            return;
        }

        require(
            amount <= withdrawalAllowance[msg.sender],
            "You don't have approval for this amount"
        );
        require(amount <= treasureAmount, "Not enough treasure in the chest");

        withdrawalAllowance[msg.sender] -= amount;
        treasureAmount -= amount;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}
