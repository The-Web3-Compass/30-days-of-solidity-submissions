// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract PremiumDepositBox is IDepositBox {
    address private _owner;
    address private _emergencyContact;
    string private _secretHash;
    BoxStatus private _status;
    uint256 private _creationTime;
    uint256 private _balance;
    
    string public constant BOX_TYPE = "Premium";
    uint256 public constant MIN_DEPOSIT = 0.1 ether;
    uint256 public constant EMERGENCY_DELAY = 7 days;

    mapping(address => bool) public authorizedUsers;
    mapping(bytes32 => uint256) public pendingWithdrawals;
    mapping(bytes32 => bool) public approvedWithdrawals;

    uint256 private _emergencyActivationTime;
    bool private _emergencyActivated;
    
    event EmergencyContactSet(address indexed emergencyContact);
    event EmergencyActivated(uint256 activationTime);
    event EmergencyWithdrawal(address indexed emergencyContact, uint256 amount);
    event UserAuthorized(address indexed user);
    event UserDeauthorized(address indexed user);
    event WithdrawalRequested(bytes32 indexed requestId, address indexed requester, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "PremiumDepositBox: caller is not the owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == _owner || authorizedUsers[msg.sender], "PremiumDepositBox: not authorized");
        _;
    }
    
    modifier onlyWhenActive() {
        require(_status == BoxStatus.Active, "PremiumDepositBox: box is not active");
        _;
    }
    
    modifier onlyEmergencyContact() {
        require(msg.sender == _emergencyContact, "PremiumDepositBox: caller is not emergency contact");
        _;
    }
    
    constructor(address initialOwner, address emergencyContact) {
        require(initialOwner != address(0), "PremiumDepositBox: owner cannot be zero address");
        require(emergencyContact != address(0), "PremiumDepositBox: emergency contact cannot be zero address");
        require(initialOwner != emergencyContact, "PremiumDepositBox: owner and emergency contact cannot be the same");
        
        _owner = initialOwner;
        _emergencyContact = emergencyContact;
        _status = BoxStatus.Active;
        _creationTime = block.timestamp;
        
        emit EmergencyContactSet(emergencyContact);
    }
    
    function deposit() external payable override onlyWhenActive {
        require(msg.value >= MIN_DEPOSIT, "PremiumDepositBox: deposit too small");
        
        _balance += msg.value;
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    function withdraw(uint256 amount) external override onlyAuthorized onlyWhenActive {
        require(amount > 0, "PremiumDepositBox: amount must be greater than 0");
        require(_balance >= amount, "PremiumDepositBox: insufficient balance");

        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp));
        pendingWithdrawals[requestId] = amount;
        
        emit WithdrawalRequested(requestId, msg.sender, amount);

        if (msg.sender == _owner) {
            approvedWithdrawals[requestId] = true;
            _executeWithdrawal(requestId, amount);
        }
    }
    
    function approveWithdrawal(bytes32 requestId) external onlyOwner {
        require(pendingWithdrawals[requestId] > 0, "PremiumDepositBox: invalid request ID");
        require(!approvedWithdrawals[requestId], "PremiumDepositBox: already approved");
        
        approvedWithdrawals[requestId] = true;
        _executeWithdrawal(requestId, pendingWithdrawals[requestId]);
    }
    
    function _executeWithdrawal(bytes32 requestId, uint256 amount) internal {
        _balance -= amount;
        payable(_owner).transfer(amount);
        
        // Clean up
        delete pendingWithdrawals[requestId];
        delete approvedWithdrawals[requestId];
        
        emit Withdrawal(_owner, amount, block.timestamp);
    }
    
    function withdrawAll() external override onlyOwner onlyWhenActive {
        uint256 amount = _balance;
        require(amount > 0, "PremiumDepositBox: no balance to withdraw");
        
        _balance = 0;
        payable(_owner).transfer(amount);
        
        emit Withdrawal(_owner, amount, block.timestamp);
    }
    
    function storeSecret(string memory secretHash) external override onlyOwner {
        _secretHash = secretHash;
        emit SecretStored(_owner, secretHash);
    }
    
    function getSecret() external view override onlyAuthorized returns (string memory) {
        return _secretHash;
    }
    
    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "PremiumDepositBox: new owner cannot be zero address");
        require(newOwner != _owner, "PremiumDepositBox: new owner is the same as current owner");
        require(newOwner != _emergencyContact, "PremiumDepositBox: new owner cannot be emergency contact");
        
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
    
    
    function authorizeUser(address user) external onlyOwner {
        require(user != address(0), "PremiumDepositBox: user cannot be zero address");
        require(!authorizedUsers[user], "PremiumDepositBox: user already authorized");
        
        authorizedUsers[user] = true;
        emit UserAuthorized(user);
    }
    
    function deauthorizeUser(address user) external onlyOwner {
        require(authorizedUsers[user], "PremiumDepositBox: user not authorized");
        
        authorizedUsers[user] = false;
        emit UserDeauthorized(user);
    }
    
    function activateEmergency() external onlyEmergencyContact {
        require(!_emergencyActivated, "PremiumDepositBox: emergency already activated");
        
        _emergencyActivated = true;
        _emergencyActivationTime = block.timestamp;
        
        emit EmergencyActivated(_emergencyActivationTime);
    }
    
    function emergencyWithdraw() external onlyEmergencyContact {
        require(_emergencyActivated, "PremiumDepositBox: emergency not activated");
        require(
            block.timestamp >= _emergencyActivationTime + EMERGENCY_DELAY,
            "PremiumDepositBox: emergency delay not met"
        );
        
        uint256 amount = _balance;
        require(amount > 0, "PremiumDepositBox: no balance to withdraw");
        
        _balance = 0;
        _status = BoxStatus.Closed;
        
        payable(_emergencyContact).transfer(amount);
        
        emit EmergencyWithdrawal(_emergencyContact, amount);
    }
    
    function getEmergencyInfo() external view returns (
        address emergencyContact,
        bool emergencyActivated,
        uint256 emergencyActivationTime,
        uint256 timeUntilWithdrawal
    ) {
        uint256 timeRemaining = 0;
        if (_emergencyActivated && block.timestamp < _emergencyActivationTime + EMERGENCY_DELAY) {
            timeRemaining = (_emergencyActivationTime + EMERGENCY_DELAY) - block.timestamp;
        }
        
        return (_emergencyContact, _emergencyActivated, _emergencyActivationTime, timeRemaining);
    }
}
