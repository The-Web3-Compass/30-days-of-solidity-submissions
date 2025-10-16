// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract AdminOnly {
    address public admin;
    uint256 public treasureAmount;
    // 每个人分配的提款额度，只要额度还有就可一直提取
    mapping(address => uint256) public withdrawalAllowance;

    // 合约部署者为管理员
    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function addTreasure(uint256 amount) public onlyAdmin {
        treasureAmount += amount;
    }

    function distributeTreasure(address recipient, uint256 amount) public onlyAdmin {
        require(amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[recipient] += amount;
        treasureAmount -= amount;
    }

    // 提取当前合约调用者的宝藏
    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == admin) {
            require(amount <= treasureAmount, "Not enough treasure available");
            treasureAmount -= amount;
            return;
        }

        // 当前合约调用者宝藏额度
        uint256 allowance = withdrawalAllowance[msg.sender];

        // 1. 当前合约宝藏有额度
        // 2. 提取金额小于宝藏额度
        require(allowance > 0 
                && amount <= allowance, "You don't have enough allowance");

        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] -= amount;
    }

    function getTreasureDetails() public view returns (uint256 totalTreasure, uint256 callerAllowance) {
        totalTreasure = treasureAmount;
        callerAllowance = withdrawalAllowance[msg.sender];
    }
    
    function getUserAllowance(address user) public view returns (uint256) {
        return withdrawalAllowance[user];
    }

    function transfer(address newOwner) public onlyAdmin {
        require(newOwner != address(0), "Invalid address");
        admin = newOwner;
    }
}