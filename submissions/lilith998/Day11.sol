// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Reusable ownership control contract
contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Main vault contract inheriting ownership control
contract VaultMaster is Ownable {
    event FundsDeposited(address indexed sender, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    // Withdraw entire balance to owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Vault: no funds available");
        
        payable(owner()).transfer(balance);
        emit FundsWithdrawn(owner(), balance);
    }
    
    // Withdraw specific amount to owner
    function withdrawAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Vault: amount must be > 0");
        require(address(this).balance >= amount, "Vault: insufficient funds");
        
        payable(owner()).transfer(amount);
        emit FundsWithdrawn(owner(), amount);
    }
    
    // Withdraw to custom address (owner only)
    function withdrawTo(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Vault: invalid recipient");
        require(amount > 0, "Vault: amount must be > 0");
        require(address(this).balance >= amount, "Vault: insufficient funds");
        
        recipient.transfer(amount);
        emit FundsWithdrawn(recipient, amount);
    }
    
    // Check vault balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Additional security: Explicitly disable renouncing ownership
    function renounceOwnership() public virtual onlyOwner {
        revert("Vault: ownership renunciation disabled");
    }
}