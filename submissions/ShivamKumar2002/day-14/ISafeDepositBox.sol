// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISafeDepositBox
 * @author shivam
 * @notice Interface defining the standard functions for all Safe Deposit Box types.
 * @dev This allows the VaultManager contract to interact with different box implementations in a uniform way (Abstraction).
 */
interface ISafeDepositBox {
    /// @notice Store a secret string in the box
    /// @param _originalSender The address of the user initiating the action via VaultManager
    /// @param _secret Secret string to store
    /// @dev Use modifier to restrict access to only owner
    function storeSecret(address _originalSender, string memory _secret) external;

    /// @notice Get the stored secret string
    /// @param _originalSender The address of the user initiating the action via VaultManager
    /// @return secret Stored secret string
    /// @dev Use modifier to restrict access to only owner
    function getSecret(address _originalSender) external view returns (string memory);

    /// @notice Get current owner of the box
    /// @return address Addrss of current owner
    function getOwner() external view returns (address);

    /// @notice Transfer ownership of box
    /// @param _originalSender The address of the user initiating the action via VaultManager
    /// @param newOwner Address of new owner
    /// @dev Use modifier to restrict access to only owner
    function transferOwnership(address _originalSender, address newOwner) external;
}