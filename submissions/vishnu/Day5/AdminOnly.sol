// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint public totalTreasure;
    string public chestName;
    

    mapping(address => uint) public allowances;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint) public totalWithdrawnByUser;

    event TreasureAdded(uint amount, uint newTotal, address indexed addedBy);
    event AllowanceGranted(address indexed user, uint amount, address indexed grantedBy);
    event TreasureWithdrawn(address indexed user, uint amount, uint remainingBalance);
    event WithdrawalStatusReset(address indexed user, address indexed resetBy);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event AllowanceRevoked(address indexed user, address indexed revokedBy);
    

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the treasure chest owner can perform this action");
        _;
    }
    
    modifier hasAllowance(uint _amount) {
        require(allowances[msg.sender] >= _amount, "Insufficient allowance to withdraw this amount");
        _;
    }
    
    modifier hasSufficientTreasure(uint _amount) {
        require(totalTreasure >= _amount, "Not enough treasure in the chest");
        _;
    }
    
    modifier hasNotWithdrawnBefore() {
        require(!hasWithdrawn[msg.sender], "You have already made a withdrawal");
        _;
    }
    

    constructor(string memory _chestName) {
        owner = msg.sender;
        chestName = _chestName;
        totalTreasure = 0;
    }

    function addTreasure() external payable onlyOwner {
        require(msg.value > 0, "Must send some treasure to add");
        totalTreasure += msg.value;
        emit TreasureAdded(msg.value, totalTreasure, msg.sender);
    }
    

    function grantAllowance(address _user, uint _amount) external onlyOwner {
        require(_user != address(0), "Cannot grant allowance to zero address");
        require(_amount > 0, "Allowance must be greater than 0");
        
        allowances[_user] = _amount;
        emit AllowanceGranted(_user, _amount, msg.sender);
    }
    

    function grantMultipleAllowances(
        address[] calldata _users, 
        uint[] calldata _amounts
    ) external onlyOwner {
        require(_users.length == _amounts.length, "Arrays must have same length");
        
        for (uint i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Cannot grant allowance to zero address");
            require(_amounts[i] > 0, "Allowance must be greater than 0");
            
            allowances[_users[i]] = _amounts[i];
            emit AllowanceGranted(_users[i], _amounts[i], msg.sender);
        }
    }
    

    function revokeAllowance(address _user) external onlyOwner {
        allowances[_user] = 0;
        emit AllowanceRevoked(_user, msg.sender);
    }
    

    function resetWithdrawalStatus(address _user) external onlyOwner {
        hasWithdrawn[_user] = false;
        emit WithdrawalStatusReset(_user, msg.sender);
    }
    

    function ownerWithdraw(uint _amount) external onlyOwner hasSufficientTreasure(_amount) {
        totalTreasure -= _amount;
        payable(owner).transfer(_amount);
        emit TreasureWithdrawn(owner, _amount, totalTreasure);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner must be different from current owner");
        
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
    

    function withdrawTreasure(uint _amount) external 
        hasAllowance(_amount) 
        hasSufficientTreasure(_amount) 
        hasNotWithdrawnBefore() 
    {
        require(_amount > 0, "Amount must be greater than 0");
        require(msg.sender != owner, "Owner should use ownerWithdraw function");
        

        hasWithdrawn[msg.sender] = true;
        allowances[msg.sender] -= _amount;
        totalWithdrawnByUser[msg.sender] += _amount;
        totalTreasure -= _amount;

        payable(msg.sender).transfer(_amount);
        
        emit TreasureWithdrawn(msg.sender, _amount, totalTreasure);
    }
    

    function checkAllowance(address _user) external view returns (uint) {
        return allowances[_user];
    }

    function checkWithdrawalStatus(address _user) external view returns (bool) {
        return hasWithdrawn[_user];
    }
    

    function getChestInfo() external view returns (
        string memory name,
        address chestOwner,
        uint treasureAmount,
        uint contractBalance
    ) {
        return (chestName, owner, totalTreasure, address(this).balance);
    }
    

    function getUserStatus(address _user) external view returns (
        uint allowance,
        bool hasWithdrawnBefore,
        uint totalWithdrawn
    ) {
        return (
            allowances[_user],
            hasWithdrawn[_user],
            totalWithdrawnByUser[_user]
        );
    }
    

    function canUserWithdraw(address _user, uint _amount) external view returns (bool, string memory) {
        if (hasWithdrawn[_user]) {
            return (false, "User has already withdrawn");
        }
        if (allowances[_user] < _amount) {
            return (false, "Insufficient allowance");
        }
        if (totalTreasure < _amount) {
            return (false, "Not enough treasure in chest");
        }
        if (_user == owner) {
            return (false, "Owner should use ownerWithdraw");
        }
        return (true, "User can withdraw");
    }

    function auditBalance() external view returns (uint contractBalance, uint recordedTreasure, bool matches) {
        uint balance = address(this).balance;
        return (balance, totalTreasure, balance == totalTreasure);
    }
}
