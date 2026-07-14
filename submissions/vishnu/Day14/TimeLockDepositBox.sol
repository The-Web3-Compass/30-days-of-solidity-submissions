// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract TimeLockDepositBox is IDepositBox {
    address private _owner;
    string private _secretHash;
    BoxStatus private _status;
    uint256 private _creationTime;
    uint256 private _balance;
    uint256 private _unlockTime;
    
    string public constant BOX_TYPE = "TimeLock";
    uint256 public constant MIN_DEPOSIT = 0.05 ether;
    uint256 public constant MIN_LOCK_PERIOD = 1 days;
    uint256 public constant MAX_LOCK_PERIOD = 365 days;
    
    event LockTimeSet(uint256 unlockTime);
    event EarlyWithdrawalAttempt(address indexed owner, uint256 attemptTime, uint256 unlockTime);
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "TimeLockDepositBox: caller is not the owner");
        _;
    }
    
    modifier onlyWhenActive() {
        require(_status == BoxStatus.Active, "TimeLockDepositBox: box is not active");
        _;
    }
    
    modifier onlyWhenUnlocked() {
        require(block.timestamp >= _unlockTime, "TimeLockDepositBox: box is still locked");
        _;
    }
    
    constructor(address initialOwner, uint256 lockPeriod) {
        require(initialOwner != address(0), "TimeLockDepositBox: owner cannot be zero address");
        require(lockPeriod >= MIN_LOCK_PERIOD, "TimeLockDepositBox: lock period too short");
        require(lockPeriod <= MAX_LOCK_PERIOD, "TimeLockDepositBox: lock period too long");
        
        _owner = initialOwner;
        _status = BoxStatus.Active;
        _creationTime = block.timestamp;
        _unlockTime = block.timestamp + lockPeriod;
        
        emit LockTimeSet(_unlockTime);
    }
    
    function deposit() external payable override onlyWhenActive {
        require(msg.value >= MIN_DEPOSIT, "TimeLockDepositBox: deposit too small");
        
        _balance += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    function withdraw(uint256 amount) external override onlyOwner onlyWhenActive onlyWhenUnlocked {
        require(amount > 0, "TimeLockDepositBox: amount must be greater than 0");
        require(_balance >= amount, "TimeLockDepositBox: insufficient balance");
        
        _balance -= amount;
        payable(_owner).transfer(amount);
        
        emit Withdrawal(_owner, amount, block.timestamp);
    }
    
    function withdrawAll() external override onlyOwner onlyWhenActive onlyWhenUnlocked {
        uint256 amount = _balance;
        require(amount > 0, "TimeLockDepositBox: no balance to withdraw");
        
        _balance = 0;
        payable(_owner).transfer(amount);
        
        emit Withdrawal(_owner, amount, block.timestamp);
    }
    
    function storeSecret(string memory secretHash) external override onlyOwner {
        _secretHash = secretHash;
        emit SecretStored(_owner, secretHash);
    }
    
    function getSecret() external view override onlyOwner returns (string memory) {
        return _secretHash;
    }
    
    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "TimeLockDepositBox: new owner cannot be zero address");
        require(newOwner != _owner, "TimeLockDepositBox: new owner is the same as current owner");
        
        address previousOwner = _owner;
        _owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    function owner() external view override returns (address) {
        return _owner;
    }
    
    function getBoxInfo() external view override returns (
        string memory boxType,
        BoxStatus status,
        uint256 balance,
        address currentOwner,
        uint256 creationTime
    ) {
        return (BOX_TYPE, _status, _balance, _owner, _creationTime);
    }
    
    function getStatus() external view override returns (BoxStatus) {
        if (_status == BoxStatus.Active && block.timestamp < _unlockTime) {
            return BoxStatus.Locked;
        }
        return _status;
    }
    
    function canWithdraw() external view override returns (bool) {
        return _status == BoxStatus.Active && _balance > 0 && block.timestamp >= _unlockTime;
    }
    
    function canDeposit() external view override returns (bool) {
        return _status == BoxStatus.Active;
    }
    
    // TimeLock specific functions
    
    function getUnlockTime() external view returns (uint256) {
        return _unlockTime;
    }
    
    function getTimeUntilUnlock() external view returns (uint256) {
        if (block.timestamp >= _unlockTime) {
            return 0;
        }
        return _unlockTime - block.timestamp;
    }
    
    function isUnlocked() external view returns (bool) {
        return block.timestamp >= _unlockTime;
    }
    
    function attemptEarlyWithdraw() external onlyOwner {
        require(block.timestamp < _unlockTime, "TimeLockDepositBox: box is already unlocked");
        
        emit EarlyWithdrawalAttempt(_owner, block.timestamp, _unlockTime);
        revert("TimeLockDepositBox: cannot withdraw before unlock time");
    }
}
