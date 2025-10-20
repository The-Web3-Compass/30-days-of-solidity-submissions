// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

contract VaultMaster is Ownable {
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);
    event EmergencyLock(address indexed owner, bool locked);
    
    bool public emergencyLock;
    
    constructor() payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external onlyOwner {
        require(!emergencyLock, "Vault is emergency locked");
        require(amount <= address(this).balance, "Insufficient balance");
        
        payable(owner).transfer(amount);
        emit Withdrawal(owner, amount);
    }
    
    function withdrawAll() external onlyOwner {
        require(!emergencyLock, "Vault is emergency locked");
        uint256 balance = address(this).balance;
        
        payable(owner).transfer(balance);
        emit Withdrawal(owner, balance);
    }
    
    function toggleEmergencyLock() external onlyOwner {
        emergencyLock = !emergencyLock;
        emit EmergencyLock(owner, emergencyLock);
    }
    
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function transferOwnership(address newOwner) public override onlyOwner {
        require(!emergencyLock, "Cannot transfer during emergency lock");
        super.transferOwnership(newOwner);
    }
}
