// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract BasicDepositBox is IDepositBox {
    address private _owner;
    string private _secretHash;
    BoxStatus private _status;
    uint256 private _creationTime;
    uint256 private _balance;
    
    string public constant BOX_TYPE = "Basic";
    uint256 public constant MIN_DEPOSIT = 0.01 ether;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "BasicDepositBox: caller is not the owner");
        _;
    }
    
    modifier onlyWhenActive() {
        require(_status == BoxStatus.Active, "BasicDepositBox: box is not active");
        _;
    }
    
    constructor(address initialOwner) {
        require(initialOwner != address(0), "BasicDepositBox: owner cannot be zero address");
        _owner = initialOwner;
        _status = BoxStatus.Active;
        _creationTime = block.timestamp;
    }
    
    function deposit() external payable override onlyWhenActive {
        require(msg.value >= MIN_DEPOSIT, "BasicDepositBox: deposit too small");
        
        _balance += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    function withdraw(uint256 amount) external override onlyOwner onlyWhenActive {
        require(amount > 0, "BasicDepositBox: amount must be greater than 0");
        require(_balance >= amount, "BasicDepositBox: insufficient balance");
        
        _balance -= amount;
        payable(_owner).transfer(amount);
        
        emit Withdrawal(_owner, amount, block.timestamp);
    }
    
    function withdrawAll() external override onlyOwner onlyWhenActive {
        uint256 amount = _balance;
        require(amount > 0, "BasicDepositBox: no balance to withdraw");
        
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
        require(newOwner != address(0), "BasicDepositBox: new owner cannot be zero address");
        require(newOwner != _owner, "BasicDepositBox: new owner is the same as current owner");
        
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
        return _status;
    }
    
    function canWithdraw() external view override returns (bool) {
        return _status == BoxStatus.Active && _balance > 0;
    }
    
    function canDeposit() external view override returns (bool) {
        return _status == BoxStatus.Active;
    }
    
    function setStatus(BoxStatus newStatus) external onlyOwner {
        BoxStatus previousStatus = _status;
        _status = newStatus;
        emit BoxStatusChanged(previousStatus, newStatus);
    }
}
