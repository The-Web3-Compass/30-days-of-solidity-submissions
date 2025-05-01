// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GoldVault {
    mapping(address => uint256) public balances;
    uint256 public totalBalance;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // Reentrancy protection state
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // Deposit ETH (safe)
    function deposit() external payable {
        require(msg.value > 0, "Amount must be > 0");
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Vulnerable function (for demonstration)
    function vulnerableWithdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // UNSAFE: State update AFTER transfer (reentrancy risk)
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        balances[msg.sender] = 0; // Too late! Attacker can re-enter.
    }

    // Secure withdrawal (uses Checks-Effects-Interactions + reentrancy guard)
    function safeWithdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // 1. CHECK: Done above
        // 2. EFFECTS: Update state BEFORE transfer
        balances[msg.sender] = 0;
        totalBalance -= amount;

        // 3. INTERACTIONS: Safe ETH transfer
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // Optional: Standard withdraw with amount parameter
    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        totalBalance -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // Helper to check contract's ETH balance
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}