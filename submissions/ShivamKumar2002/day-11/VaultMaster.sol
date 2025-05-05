// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import the Ownable contract from the other file
import "./Ownable.sol";

/**
 * @title VaultMaster
 * @author shivam
 * @notice A simple contract to simulate a vault where only the owner (master key holder) can withdraw funds or transfer the ownership of the vault.
 * @dev Inherits ownership control from the Ownable contract
 */
contract VaultMaster is Ownable {
    /// @notice Event emitted when a deposit is made by a user.
    /// @param from Depositor address
    /// @param amount Deposit amount value
    event Deposited(address indexed from, uint256 indexed amount);

    /// @notice Event emitted when a withdrawal is made by a user.
    /// @param to User address
    /// @param amount Deposit amount value
    event Withdrew(address indexed to, uint256 indexed amount);

    /// @notice Error thrown when available amount in insufficient for withdrawal.
    /// @param requested Withdrawal amount requested
    /// @param available Available amount
    error InsufficientFunds(uint256 requested, uint256 available);

    /// @notice Initializes the contract. Constructor of Ownable is called implicitly.
    constructor() Ownable() {}

    /// @notice Special function that allows this contract to receive ETH.
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Fallback function to receive ETH when calldata is not empty
    fallback() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Get balance of the contract
    /// @return balance Balance in wei
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Withdraw specified amount from vault to given address. Can only be called by the owner.
    /// @param _to Receiver address
    /// @param _amount Withdrawal amount (in wei)
    /// @custom:error InsufficientFunds when `_amount` is greater than available balance
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "invalid withdrawal address");

        // check amount
        require(_amount > 0, "withdrawal amount must be greater than 0");
        if (_amount > address(this).balance) {
            revert InsufficientFunds(_amount, address(this).balance);
        }

        // transfer amount
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "ETH transfer failed");

        // emit event
        emit Withdrew(_to, _amount);
    }
}
