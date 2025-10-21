// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract GoldVault {
    mapping(address => uint256) public balances;
    uint256 public totalBalance;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

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

    function deposit() external payable {
        require(msg.value > 0, "Amount must be > 0");
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function vulnerableWithdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
        
        balances[msg.sender] = 0;
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        
        balances[msg.sender] = 0;
        totalBalance -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        totalBalance -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
