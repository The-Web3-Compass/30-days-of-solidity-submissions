// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISafeDepositBox.sol";
import "./BasicDepositBox.sol";

/**
 * @title VaultManager
 * @author shivam
 * @notice A simple contract that manages different types of Safe Deposit Boxes through a common interface.
 * @dev Currently it supports BasicDepositBox as example
 */
contract VaultManager {
    // Mapping from user address to an array of their deposit box addresses
    mapping(address => address[]) public userBoxes;

    // Array to keep track of all created boxes
    address[] public allBoxes;

    /// @notice Event emitted when a new deposit box is created
    /// @param owner The owner of the new box
    /// @param boxAddress The address of the newly created box contract
    /// @param boxType The type name of the box created (e.g., "BasicDepositBox")
    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);

    /**
     * @notice Creates a new BasicDepositBox, assigns ownership, and registers the VaultManager.
     * @return newBoxAddress The address of the newly created box contract
     * @dev Deploys a BasicDepositBox, passing user and this contract's address.
     */
    function createBasicDepositBox() external returns (address newBoxAddress) {
        // Pass msg.sender as owner and address(this) as the trusted VaultManager
        BasicDepositBox newBox = new BasicDepositBox(msg.sender, address(this));
        newBoxAddress = address(newBox);

        // Add the new box to the state
        userBoxes[msg.sender].push(newBoxAddress);
        allBoxes.push(newBoxAddress);

        // Emit event
        emit BoxCreated(msg.sender, newBoxAddress, "BasicDepositBox");
    }

    /**
     * @notice Get all deposit box addresses owned by the caller
     * @return addresses An array of addresses representing the caller's deposit boxes
     */
    function getMyBoxes() external view returns (address[] memory) {
        return userBoxes[msg.sender];
    }

    /**
     * @notice Gets the secret from a specific deposit box via delegation.
     * @param _boxAddress The address of the deposit box contract
     * @return secret The secret string stored in the box
     */
    function getSecretFromBox(address _boxAddress) external view returns (string memory) {
        require(_boxAddress != address(0), "VaultManager: Invalid box address");
        ISafeDepositBox box = ISafeDepositBox(_boxAddress);
        // Pass msg.sender as the original caller
        return box.getSecret(msg.sender);
    }

    /**
     * @notice Stores a secret in a specific deposit box via delegation.
     * @param _boxAddress The address of the deposit box contract
     * @param _secret The secret string to store
     */
    function storeSecretInBox(address _boxAddress, string memory _secret) external {
        require(_boxAddress != address(0), "VaultManager: Invalid box address");
        ISafeDepositBox box = ISafeDepositBox(_boxAddress);
        // Pass msg.sender as the original caller
        box.storeSecret(msg.sender, _secret);
    }

    /**
     * @notice Transfers ownership of a specific deposit box via delegation.
     * @param _boxAddress The address of the deposit box contract
     * @param _newOwner The address of the new owner
     */
    function transferBoxOwnership(address _boxAddress, address _newOwner) external {
        require(_boxAddress != address(0), "VaultManager: Invalid box address");
        require(_newOwner != address(0), "VaultManager: Invalid new owner address");
        
        ISafeDepositBox box = ISafeDepositBox(_boxAddress);
        address currentOwner = msg.sender; // This is the original user initiating the transfer

        // Call transfer ownership on the box contract itself, passing the original caller
        box.transferOwnership(currentOwner, _newOwner);

        // update the mapping (logic remains the same as before)
        // Remove from the current owner's list
        address[] storage currentOwnerBoxes = userBoxes[currentOwner];
        uint256 boxIndex = type(uint256).max;
        for (uint256 i = 0; i < currentOwnerBoxes.length; i++) {
            if (currentOwnerBoxes[i] == _boxAddress) {
                boxIndex = i;
                break;
            }
        }

        assert(boxIndex != type(uint256).max);
        
        currentOwnerBoxes[boxIndex] = currentOwnerBoxes[currentOwnerBoxes.length - 1];
        currentOwnerBoxes.pop();
        userBoxes[currentOwner] = currentOwnerBoxes;
        userBoxes[_newOwner].push(_boxAddress);
    }
}
