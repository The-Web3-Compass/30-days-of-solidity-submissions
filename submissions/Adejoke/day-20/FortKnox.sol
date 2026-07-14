
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

abstract contract ReentrancyGuard {
    uint256 private _status;
    constructor() { _status = 1; }
    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }
}

contract FortKnox is ReentrancyGuard {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public pendingWithdrawals;
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    // Pattern 1: Checks-Effects-Interactions + Reentrancy Guard
    function safeWithdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance"); // CHECKS
        
        balances[msg.sender] = 0; // EFFECTS
        
        (bool sent, ) = msg.sender.call{value: amount}(""); // INTERACTIONS
        require(sent, "Transfer failed");
    }

    // Pattern 2: Pull Over Push (Users initiate separate withdrawal mechanisms)
    function initiateWithdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");
        
        balances[msg.sender] = 0;
        pendingWithdrawals[msg.sender] += amount;
    }
    
    function pullWithdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        
        pendingWithdrawals[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
    }
}
