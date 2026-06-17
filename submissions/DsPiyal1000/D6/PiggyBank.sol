// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PiggyBank {
    // State variables
    address public bankManager;
    address[] public members;
    
    uint256 public cooldownTime = 1 days;
    uint256 public maxWithdrawLimit = 1 ether;
    
    // Mappings
    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastWithdrawTime;
    
    // Events
    event MemberAdded(address indexed member);
    event Deposited(address indexed member, uint256 amount);
    event Withdrawn(address indexed member, uint256 amount);
    event CooldownTimeUpdated(uint256 oldTime, uint256 newTime);
    event MaxWithdrawLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event ManagershipTransferred(address indexed oldManager, address indexed newManager);
    
    // Custom errors
    error Unauthorized();
    error NotRegistered();
    error InvalidAddress();
    error AlreadyRegistered();
    error InvalidAmount();
    error InsufficientFunds();
    error ExceedsWithdrawalLimit();
    error CooldownActive();
    error TransferFailed();

    constructor() {
        bankManager = msg.sender;
        members.push(msg.sender);
        registeredMembers[msg.sender] = true;
        
        emit MemberAdded(msg.sender);
    }

    modifier onlyBankManager() {
        if (msg.sender != bankManager) revert Unauthorized();
        _;
    }

    modifier onlyRegisteredMembers() {
        if (!registeredMembers[msg.sender]) revert NotRegistered();
        _;
    }

    function addMember(address _member) external onlyBankManager {
        if (_member == address(0)) revert InvalidAddress();
        if (_member == bankManager) revert InvalidAddress();
        if (registeredMembers[_member]) revert AlreadyRegistered();

        registeredMembers[_member] = true;
        members.push(_member);
        
        emit MemberAdded(_member);
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    function deposit(uint256 _amount) external onlyRegisteredMembers {
        if (_amount == 0) revert InvalidAmount();
        
        balance[msg.sender] += _amount;
        
        emit Deposited(msg.sender, _amount);
    }

    function depositAmountEther() external payable onlyRegisteredMembers {
        if (msg.value == 0) revert InvalidAmount();
        
        balance[msg.sender] += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external onlyRegisteredMembers {
        if (_amount == 0) revert InvalidAmount();
        if (_amount > balance[msg.sender]) revert InsufficientFunds();
        if (_amount > maxWithdrawLimit) revert ExceedsWithdrawalLimit();
        if (block.timestamp < lastWithdrawTime[msg.sender] + cooldownTime) revert CooldownActive();

        // Update state before transfer to prevent reentrancy
        balance[msg.sender] -= _amount;
        lastWithdrawTime[msg.sender] = block.timestamp;
        
        emit Withdrawn(msg.sender, _amount);
        
        // Use call instead of transfer for better compatibility
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) revert TransferFailed();
    }

    function getBalance(address _member) external view returns (uint256) {
        if (_member == address(0)) revert InvalidAddress();
        return balance[_member];
    }

    function setCooldownTime(uint256 _cooldown) external onlyBankManager {
        uint256 oldCooldown = cooldownTime;
        cooldownTime = _cooldown;
        
        emit CooldownTimeUpdated(oldCooldown, _cooldown);
    }

    function setMaxWithdrawLimit(uint256 _limit) external onlyBankManager {
        uint256 oldLimit = maxWithdrawLimit;
        maxWithdrawLimit = _limit;
        
        emit MaxWithdrawLimitUpdated(oldLimit, _limit);
    }
    
    function transferManagership(address _newManager) external onlyBankManager {
        if (_newManager == address(0)) revert InvalidAddress();
        
        address oldManager = bankManager;
        bankManager = _newManager;
        
        // Ensure the new manager is a registered member
        if (!registeredMembers[_newManager]) {
            registeredMembers[_newManager] = true;
            members.push(_newManager);
            emit MemberAdded(_newManager);
        }
        
        emit ManagershipTransferred(oldManager, _newManager);
    }
    
    function cooldownRemaining(address _member) external view returns (uint256) {
        uint256 lastWithdraw = lastWithdrawTime[_member];
        if (lastWithdraw == 0 || block.timestamp >= lastWithdraw + cooldownTime) {
            return 0;
        }
        return lastWithdraw + cooldownTime - block.timestamp;
    }

    receive() external payable {
        if (!registeredMembers[msg.sender]) revert NotRegistered();
        
        balance[msg.sender] += msg.value;
        
        emit Deposited(msg.sender, msg.value);
    }
}