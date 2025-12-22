// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

/**
 * @title Simple treasure administrator
 * @author Eric (https://github.com/0xxEric)
 * @notice A contract that control a treasure chest by administrator
 * @custom:project 30-days-of-solidity-submissions: Day05
 */
contract AdminOnly {
    address public admin;
    uint256 totalAmount;
    uint256 totoalApproved;
    uint256 a;
    mapping(address => uint256) approvalAmount;
    mapping(address => uint256) withdrawAmount;

    constructor(uint256 amount) {
        admin = msg.sender;
        totalAmount = amount;
    }

    modifier Onlyadmin() {
        require(msg.sender == admin, "Only admin can transfer the authority ");
        _;
    }

    function adminTransfer(address newadmin) external Onlyadmin {
        admin = newadmin;
    }

    function setApproval(address to, uint256 amount) external Onlyadmin {
        require(to != address(0), "zero address");
        require(amount > 0, "amount should >0");
        require(
            (totoalApproved + amount) <= totalAmount,
            "Insufficient approval"
        );
        approvalAmount[to] += amount;
        totoalApproved += amount;
    }

    function resetApproval(address to) external Onlyadmin {
        require(to != address(0), "zero address");
        totoalApproved += approvalAmount[to];
        approvalAmount[to] = 0;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "amount should >0");
        require(amount < approvalAmount[msg.sender], "amount should >0");
        withdrawAmount[msg.sender] += amount;
        approvalAmount[msg.sender] -= amount;
    }
}
