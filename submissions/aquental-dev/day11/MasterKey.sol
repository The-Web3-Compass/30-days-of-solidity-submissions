// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Ownable
 * @dev Base contract providing ownership functionality with access control
 * This contract establishes the foundation for secure ownership patterns
 */
abstract contract Ownable {
    address private _owner;

    // Events for transparency and off-chain monitoring
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipRenounced(address indexed previousOwner);

    // Custom errors for gas efficiency and better debugging
    error NotOwner();
    error ZeroAddress();
    error AlreadyOwner();

    /**
     * @dev Sets the contract deployer as the initial owner
     * Emits OwnershipTransferred event with zero address as previous owner
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner
     * @return owner address
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Modifier to restrict function access to owner only
     * Reverts with NotOwner error if caller is not the owner
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    /**
     * @dev Transfers ownership to a new address
     * Can only be called by the current owner
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        if (newOwner == _owner) revert AlreadyOwner();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Renounces ownership, leaving the contract without an owner
     * Can only be called by the current owner
     * WARNING: This action is irreversible
     */
    function renounceOwnership() public virtual onlyOwner {
        address previousOwner = _owner;
        _owner = address(0);
        emit OwnershipRenounced(previousOwner);
    }

    /**
     * @dev Internal function to transfer ownership
     * Emits OwnershipTransferred event
     * @param newOwner The address to transfer ownership to
     */
    function _transferOwnership(address newOwner) internal {
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}

/**
 * @title VaultMaster
 * @dev Secure vault contract inheriting ownership controls from Ownable
 * Acts as a digital safe where only the master key holder (owner) can control funds
 */
contract MasterKey is Ownable {
    uint256 private _balance;
    bool private _emergencyStop;

    // Events for vault operations
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);
    event EmergencyStop(bool status);

    // Custom errors
    error InsufficientFunds();
    error EmergencyActive();
    error TransferFailed();

    /**
     * @dev Modifier to check if emergency stop is not active
     * Prevents operations during emergency situations
     */
    modifier whenNotStopped() {
        if (_emergencyStop) revert EmergencyActive();
        _;
    }

    /**
     * @dev Allows the contract to receive Ether deposits
     * Updates internal balance and emits Deposit event
     */
    receive() external payable {
        _balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Fallback function for receiving Ether with data
     * Updates internal balance and emits Deposit event
     */
    fallback() external payable {
        _balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Returns the current balance stored in the vault
     * @return Current balance in wei
     */
    function getBalance() public view returns (uint256) {
        return _balance;
    }

    /**
     * @dev Returns the emergency stop status
     * @return True if emergency stop is active, false otherwise
     */
    function isEmergencyStopped() public view returns (bool) {
        return _emergencyStop;
    }

    /**
     * @dev Allows owner to withdraw specified amount from the vault
     * Only callable by owner and when not in emergency stop
     * @param amount Amount to withdraw in wei
     */
    function withdraw(uint256 amount) external onlyOwner whenNotStopped {
        if (amount > _balance) revert InsufficientFunds();

        _balance -= amount;

        // Use call for secure Ether transfer
        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(owner(), amount);
    }

    /**
     * @dev Allows owner to withdraw all funds from the vault
     * Only callable by owner and when not in emergency stop
     */
    function withdrawAll() external onlyOwner whenNotStopped {
        uint256 amount = _balance;
        if (amount == 0) revert InsufficientFunds();

        _balance = 0;

        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(owner(), amount);
    }

    /**
     * @dev Emergency stop mechanism - owner can halt all operations
     * Only callable by owner
     * @param stop True to activate emergency stop, false to deactivate
     */
    function setEmergencyStop(bool stop) external onlyOwner {
        _emergencyStop = stop;
        emit EmergencyStop(stop);
    }

    /**
     * @dev Allows owner to make emergency withdrawal during emergency stop
     * Bypasses normal withdrawal restrictions for critical situations
     * Only callable by owner
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 amount = _balance;
        if (amount == 0) revert InsufficientFunds();

        _balance = 0;

        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(owner(), amount);
    }
}
