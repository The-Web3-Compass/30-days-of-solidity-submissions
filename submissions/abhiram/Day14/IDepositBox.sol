//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IDepositBox
 * @notice Interface for all deposit box types in the smart bank system
 * @dev This interface ensures all deposit boxes have a common set of functions
 */
interface IDepositBox {
    /// @notice Emitted when a secret is stored in the deposit box
    event SecretStored(address indexed owner, uint256 timestamp);
    
    /// @notice Emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /// @notice Emitted when a deposit is made
    event Deposited(address indexed depositor, uint256 amount);
    
    /// @notice Emitted when a withdrawal is made
    event Withdrawn(address indexed owner, uint256 amount);
    
    /**
     * @notice Store a secret in the deposit box
     * @param secret The secret string to store
     */
    function storeSecret(string calldata secret) external;
    
    /**
     * @notice Retrieve the stored secret
     * @return The secret string stored in the box
     */
    function retrieveSecret() external view returns (string memory);
    
    /**
     * @notice Transfer ownership of the deposit box
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external;
    
    /**
     * @notice Deposit funds into the box
     */
    function deposit() external payable;
    
    /**
     * @notice Withdraw funds from the box
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external;
    
    /**
     * @notice Get the current owner of the deposit box
     * @return Address of the current owner
     */
    function getOwner() external view returns (address);
    
    /**
     * @notice Get the balance of the deposit box
     * @return Current balance in wei
     */
    function getBalance() external view returns (uint256);
    
    /**
     * @notice Get the type of deposit box
     * @return String describing the box type
     */
    function getBoxType() external pure returns (string memory);
}
