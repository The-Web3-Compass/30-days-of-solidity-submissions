// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

/**
 * @title VaultManager
 * @notice Manages creation and administration of different DepositBox contracts for users.
 */
contract VaultManager {

    // Mapping from user address to their created deposit box addresses
    mapping(address => address[]) private userDepositBoxes;

    // Mapping to store custom names for each deposit box
    mapping(address => string) private boxNames;

    // Event emitted when a new box is created
    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);

    // Event emitted when a box is named
    event BoxNamed(address indexed boxAddress, string name);

    /**
     * @notice Creates a new BasicDepositBox for the caller
     * @return The address of the newly created BasicDepositBox
     */
    function createBasicBox() external returns (address) {
        // Deploy a new BasicDepositBox
        BasicDepositBox box = new BasicDepositBox();
        // Record the box under the caller's address
        userDepositBoxes[msg.sender].push(address(box));
        // Emit event for frontends or logs
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    /**
     * @notice Creates a new PremiumDepositBox for the caller
     * @return The address of the newly created PremiumDepositBox
     */
    function createPremiumBox() external returns (address) {
        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    /**
     * @notice Creates a new TimeLockedDepositBox with a lock duration
     * @param lockDuration The duration (in seconds) before the box can be unlocked
     * @return The address of the newly created TimeLockedDepositBox
     */
    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Time Locked");
        return address(box);
    }

    /**
     * @notice Assigns a custom name to a specific deposit box
     * @param boxAddress The address of the deposit box to name
     * @param name The custom name to assign
     */
    function nameBox(address boxAddress, string memory name) external {
        IDepositBox box = IDepositBox(boxAddress);
        // Ensure the caller is the owner of the box
        require(box.getOwner() == msg.sender, "Not the box owner");
        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    }

    /**
     * @notice Stores a secret in the specified deposit box
     * @param boxAddress The address of the deposit box
     * @param secret The secret string to store
     */
    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.storeSecret(secret);
    }

    /**
     * @notice Transfers ownership of a deposit box to a new owner
     * @param boxAddress The address of the deposit box
     * @param newOwner The address of the new owner
     */
    function transferBoxOwnership(address boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        // Call the box's transferOwnership
        box.transferOwnership(newOwner);

        // Remove box from old owner's list
        address[] storage boxes = userDepositBoxes[msg.sender];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                // Swap with last and pop
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }

        // Add box to new owner's list
        userDepositBoxes[newOwner].push(boxAddress);
    }

    /**
     * @notice Retrieves all deposit boxes created by a user
     * @param user The address of the user
     * @return An array of deposit box addresses owned by the user
     */
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    /**
     * @notice Retrieves the custom name for a given deposit box
     * @param boxAddress The address of the deposit box
     * @return The custom name assigned to the box
     */
    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxNames[boxAddress];
    }

    /**
     * @notice Retrieves detailed information about a deposit box
     * @param boxAddress The address of the deposit box
     * @return boxType The type of the box (Basic, Premium, or TimeLocked)
     * @return owner The current owner of the box
     * @return depositTime The timestamp when the box was created
     * @return name The custom name assigned to the box
     */
    function getBoxInfo(address boxAddress) external view returns (
        string memory boxType,
        address owner,
        uint256 depositTime,
        string memory name
    ) {
        IDepositBox box = IDepositBox(boxAddress);
        return (
            box.getBoxType(),
            box.getOwner(),
            box.getDepositTime(),
            boxNames[boxAddress]
        );
    }
}