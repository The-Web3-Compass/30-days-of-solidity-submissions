// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract FortKnox is ReentrancyGuard, Ownable, Pausable {
    constructor() Ownable(msg.sender) {} // you can't have a contract without defining an Owner

    mapping(address => uint256) private balances;
    uint256 public constant MAX_WITHDRAWAL = 10 ether;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit some ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external nonReentrant whenNotPaused {
        // 1. CHECKS — validate everything first
        uint256 userBalance = balances[msg.sender]; // how much do they have?
        require(userBalance > 0, "Nothing to withdraw");

        uint256 amount = userBalance > MAX_WITHDRAWAL ? MAX_WITHDRAWAL : userBalance;

        // 2. EFFECTS — update state before any external call
        balances[msg.sender] = userBalance - amount;

        // 3. INTERACTIONS — now talk to the outside world
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Transfer failed"); // confirm it worked

        emit Withdrawn(msg.sender, amount); // log the receipt
    }

    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "Transfer failed");
        emit EmergencyWithdrawal(owner(), amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
} 