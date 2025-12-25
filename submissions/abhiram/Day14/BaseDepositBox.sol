//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./IDepositBox.sol";

/**
 * @title BaseDepositBox
 * @notice Abstract base contract providing common functionality for all deposit boxes
 * @dev Implements the IDepositBox interface with core features
 */
abstract contract BaseDepositBox is IDepositBox {
    address private _owner;
    string private _secret;
    uint256 private _balance;
    
    /**
     * @notice Ensures only the owner can call the function
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @notice Initialize the deposit box with an owner
     * @param initialOwner Address of the initial owner
     */
    constructor(address initialOwner) {
        require(initialOwner != address(0), "Owner cannot be zero address");
        _owner = initialOwner;
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function storeSecret(string calldata secret) external virtual override onlyOwner {
        _secret = secret;
        emit SecretStored(_owner, block.timestamp);
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function retrieveSecret() external view virtual override onlyOwner returns (string memory) {
        return _secret;
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function deposit() external payable virtual override {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        _balance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function withdraw(uint256 amount) external virtual override onlyOwner {
        _withdraw(amount);
    }
    
    /**
     * @notice Internal withdrawal function
     * @param amount Amount to withdraw
     * @dev Can be called by derived contracts to perform withdrawal
     */
    function _withdraw(uint256 amount) internal {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(amount <= _balance, "Insufficient balance");
        
        _balance -= amount;
        (bool success, ) = payable(_owner).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(_owner, amount);
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function getOwner() external view override returns (address) {
        return _owner;
    }
    
    /**
     * @inheritdoc IDepositBox
     */
    function getBalance() external view override returns (uint256) {
        return _balance;
    }
    
    /**
     * @inheritdoc IDepositBox
     * @dev Must be implemented by derived contracts
     */
    function getBoxType() external pure virtual override returns (string memory);
}
