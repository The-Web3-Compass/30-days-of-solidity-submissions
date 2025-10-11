// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract VaultMaster is Ownable {

    mapping(address => uint) private _balances;
    mapping(address => bool) private _authorizedUsers;
    
    uint private _totalBalance;
    uint private _emergencyWithdrawalDelay;
    uint private _emergencyWithdrawalRequestTime;
    bool private _emergencyWithdrawalRequested;
    
    uint public constant MAX_WITHDRAWAL_AMOUNT = 100 ether;
    uint public constant EMERGENCY_DELAY = 1 days;
    

    enum AccessLevel { None, Viewer, Depositor, Manager, Admin }
    mapping(address => AccessLevel) private _accessLevels;
    

    event DepositMade(address indexed depositor, uint amount, uint timestamp);
    event WithdrawalMade(address indexed owner, uint amount, uint timestamp);
    event UserAuthorized(address indexed user, address indexed authorizer);
    event UserDeauthorized(address indexed user, address indexed deauthorizer);
    event EmergencyWithdrawalRequested(address indexed owner, uint requestTime);
    event EmergencyWithdrawalExecuted(address indexed owner, uint amount);
    event AccessLevelChanged(address indexed user, AccessLevel newLevel, address indexed changer);
    event VaultLocked(address indexed owner, uint lockTime);
    event VaultUnlocked(address indexed owner, uint unlockTime);

    bool private _vaultLocked;
    uint private _lockTimestamp;
    uint private _lockDuration;
    
    constructor() Ownable() {
        _emergencyWithdrawalDelay = EMERGENCY_DELAY;
        _vaultLocked = false;

        _accessLevels[msg.sender] = AccessLevel.Admin;
    }
    
    modifier onlyAuthorized() {
        require(_authorizedUsers[msg.sender] || msg.sender == owner(), 
                "VaultMaster: caller is not authorized");
        _;
    }
    
    modifier onlyAccessLevel(AccessLevel requiredLevel) {
        require(_accessLevels[msg.sender] >= requiredLevel || msg.sender == owner(), 
                "VaultMaster: insufficient access level");
        _;
    }
    
    modifier vaultNotLocked() {
        require(!_vaultLocked || block.timestamp >= _lockTimestamp + _lockDuration, 
                "VaultMaster: vault is currently locked");
        _;
    }
    
    modifier validAmount(uint amount) {
        require(amount > 0, "VaultMaster: amount must be greater than 0");
        require(amount <= MAX_WITHDRAWAL_AMOUNT, "VaultMaster: amount exceeds maximum limit");
        _;
    }
    
    function deposit() external payable vaultNotLocked {
        require(msg.value > 0, "VaultMaster: deposit amount must be greater than 0");
        
        _balances[msg.sender] += msg.value;
        _totalBalance += msg.value;
        
        emit DepositMade(msg.sender, msg.value, block.timestamp);
    }

    function depositFor(address user) external payable onlyOwner vaultNotLocked {
        require(msg.value > 0, "VaultMaster: deposit amount must be greater than 0");
        require(user != address(0), "VaultMaster: invalid user address");
        
        _balances[user] += msg.value;
        _totalBalance += msg.value;
        
        emit DepositMade(user, msg.value, block.timestamp);
    }
    
    function withdraw(uint amount) external onlyOwner vaultNotLocked validAmount(amount) {
        require(address(this).balance >= amount, "VaultMaster: insufficient vault balance");
        require(amount <= _totalBalance, "VaultMaster: amount exceeds total tracked balance");
        
        _totalBalance -= amount;
        payable(owner()).transfer(amount);
        
        emit WithdrawalMade(owner(), amount, block.timestamp);
    }
    
    function withdrawAll() external onlyOwner vaultNotLocked {
        uint amount = address(this).balance;
        require(amount > 0, "VaultMaster: no funds to withdraw");
        
        _totalBalance = 0;
        payable(owner()).transfer(amount);
        
        emit WithdrawalMade(owner(), amount, block.timestamp);
    }
    
    function requestEmergencyWithdrawal() external onlyOwner {
        require(!_emergencyWithdrawalRequested, "VaultMaster: emergency withdrawal already requested");
        
        _emergencyWithdrawalRequested = true;
        _emergencyWithdrawalRequestTime = block.timestamp;
        
        emit EmergencyWithdrawalRequested(owner(), block.timestamp);
    }
    
    function executeEmergencyWithdrawal() external onlyOwner {
        require(_emergencyWithdrawalRequested, "VaultMaster: no emergency withdrawal requested");
        require(block.timestamp >= _emergencyWithdrawalRequestTime + _emergencyWithdrawalDelay, 
                "VaultMaster: emergency delay not met");
        
        uint amount = address(this).balance;
        require(amount > 0, "VaultMaster: no funds to withdraw");
        
        _emergencyWithdrawalRequested = false;
        _emergencyWithdrawalRequestTime = 0;
        _totalBalance = 0;
        
        payable(owner()).transfer(amount);
        
        emit EmergencyWithdrawalExecuted(owner(), amount);
    }
    
    function authorizeUser(address user) external onlyOwner {
        require(user != address(0), "VaultMaster: invalid user address");
        require(!_authorizedUsers[user], "VaultMaster: user already authorized");
        
        _authorizedUsers[user] = true;
        emit UserAuthorized(user, owner());
    }

    function deauthorizeUser(address user) external onlyOwner {
        require(_authorizedUsers[user], "VaultMaster: user not authorized");
        
        _authorizedUsers[user] = false;
        emit UserDeauthorized(user, owner());
    }
    
    function setAccessLevel(address user, AccessLevel level) external onlyOwner {
        require(user != address(0), "VaultMaster: invalid user address");
        
        _accessLevels[user] = level;
        emit AccessLevelChanged(user, level, owner());
    }
    
    function lockVault(uint duration) external onlyOwner {
        require(duration > 0, "VaultMaster: lock duration must be greater than 0");
        require(!_vaultLocked, "VaultMaster: vault is already locked");
        
        _vaultLocked = true;
        _lockTimestamp = block.timestamp;
        _lockDuration = duration;
        
        emit VaultLocked(owner(), block.timestamp);
    }
    
    function unlockVault() external onlyOwner {
        require(_vaultLocked, "VaultMaster: vault is not locked");
        
        _vaultLocked = false;
        _lockTimestamp = 0;
        _lockDuration = 0;
        
        emit VaultUnlocked(owner(), block.timestamp);
    }
    
    function getVaultInfo() external view returns (
        uint totalBalance,
        uint contractBalance,
        bool isLocked,
        uint lockTimeRemaining,
        bool emergencyRequested,
        uint emergencyTimeRemaining
    ) {
        uint lockRemaining = 0;
        if (_vaultLocked && block.timestamp < _lockTimestamp + _lockDuration) {
            lockRemaining = (_lockTimestamp + _lockDuration) - block.timestamp;
        }
        
        uint emergencyRemaining = 0;
        if (_emergencyWithdrawalRequested && 
            block.timestamp < _emergencyWithdrawalRequestTime + _emergencyWithdrawalDelay) {
            emergencyRemaining = (_emergencyWithdrawalRequestTime + _emergencyWithdrawalDelay) - block.timestamp;
        }
        
        return (
            _totalBalance,
            address(this).balance,
            _vaultLocked,
            lockRemaining,
            _emergencyWithdrawalRequested,
            emergencyRemaining
        );
    }
    

    function isAuthorized(address user) external view returns (bool) {
        return _authorizedUsers[user] || user == owner();
    }
    

    function getAccessLevel(address user) external view returns (AccessLevel) {
        return _accessLevels[user];
    }

    function getUserBalance(address user) external view returns (uint) {
        return _balances[user];
    }
    
    function getTotalBalance() external view returns (uint) {
        return _totalBalance;
    }
    

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "VaultMaster: new owner is the zero address");

        _accessLevels[owner()] = AccessLevel.None;

        super.transferOwnership(newOwner);
        
        _accessLevels[newOwner] = AccessLevel.Admin;
    }

    receive() external payable {
        _balances[msg.sender] += msg.value;
        _totalBalance += msg.value;
        emit DepositMade(msg.sender, msg.value, block.timestamp);
    }

    fallback() external payable {
        revert("VaultMaster: function not found");
    }
}
