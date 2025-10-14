//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

/**
 * @title SafeDepositBox
 * @notice Central manager for all deposit boxes in the smart bank system
 * @dev Provides unified interface for creating and interacting with deposit boxes
 */
contract SafeDepositBox {
    /// @notice Emitted when a new deposit box is created
    event DepositBoxCreated(
        address indexed boxAddress,
        address indexed owner,
        string boxType,
        uint256 timestamp
    );
    
    /// @notice Emitted when a deposit box is registered
    event DepositBoxRegistered(address indexed boxAddress, address indexed owner);
    
    /// @notice Mapping from user address to their deposit boxes
    mapping(address => address[]) private userBoxes;
    
    /// @notice Mapping to check if an address is a registered deposit box
    mapping(address => bool) public isRegisteredBox;
    
    /// @notice Array of all deposit boxes created through this manager
    address[] private allBoxes;
    
    /**
     * @notice Create a new basic deposit box
     * @return Address of the newly created box
     */
    function createBasicBox() external returns (address) {
        BasicDepositBox newBox = new BasicDepositBox(msg.sender);
        address boxAddress = address(newBox);
        
        _registerBox(boxAddress, msg.sender, "Basic");
        return boxAddress;
    }
    
    /**
     * @notice Create a new premium deposit box
     * @return Address of the newly created box
     */
    function createPremiumBox() external returns (address) {
        PremiumDepositBox newBox = new PremiumDepositBox(msg.sender);
        address boxAddress = address(newBox);
        
        _registerBox(boxAddress, msg.sender, "Premium");
        return boxAddress;
    }
    
    /**
     * @notice Create a new time-locked deposit box
     * @param lockDuration Duration in seconds for which funds are locked
     * @return Address of the newly created box
     */
    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox newBox = new TimeLockedDepositBox(msg.sender, lockDuration);
        address boxAddress = address(newBox);
        
        _registerBox(boxAddress, msg.sender, "TimeLocked");
        return boxAddress;
    }
    
    /**
     * @notice Register an existing deposit box with the manager
     * @param boxAddress Address of the deposit box
     * @dev Only the box owner can register it
     */
    function registerExistingBox(address boxAddress) external {
        require(boxAddress != address(0), "Invalid box address");
        require(!isRegisteredBox[boxAddress], "Box already registered");
        
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        
        _registerBox(boxAddress, msg.sender, box.getBoxType());
    }
    
    /**
     * @notice Internal function to register a deposit box
     * @param boxAddress Address of the box
     * @param owner Owner of the box
     * @param boxType Type of the box
     */
    function _registerBox(address boxAddress, address owner, string memory boxType) private {
        userBoxes[owner].push(boxAddress);
        allBoxes.push(boxAddress);
        isRegisteredBox[boxAddress] = true;
        
        emit DepositBoxCreated(boxAddress, owner, boxType, block.timestamp);
    }
    
    /**
     * @notice Get all deposit boxes owned by a user
     * @param user Address of the user
     * @return Array of deposit box addresses
     */
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userBoxes[user];
    }
    
    /**
     * @notice Get total number of boxes created
     * @return Total count of deposit boxes
     */
    function getTotalBoxes() external view returns (uint256) {
        return allBoxes.length;
    }
    
    /**
     * @notice Get all deposit boxes
     * @return Array of all deposit box addresses
     */
    function getAllBoxes() external view returns (address[] memory) {
        return allBoxes;
    }
    
    /**
     * @notice Interact with a deposit box to store a secret
     * @param boxAddress Address of the deposit box
     * @param secret Secret to store
     * @dev Demonstrates contract-to-contract interaction
     */
    function storeSecretInBox(address boxAddress, string calldata secret) external {
        require(isRegisteredBox[boxAddress], "Box not registered");
        
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        
        box.storeSecret(secret);
    }
    
    /**
     * @notice Interact with a deposit box to retrieve a secret
     * @param boxAddress Address of the deposit box
     * @return The stored secret
     * @dev Demonstrates contract-to-contract interaction
     */
    function retrieveSecretFromBox(address boxAddress) external view returns (string memory) {
        require(isRegisteredBox[boxAddress], "Box not registered");
        
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        
        return box.retrieveSecret();
    }
    
    /**
     * @notice Transfer ownership of a deposit box
     * @param boxAddress Address of the deposit box
     * @param newOwner Address of the new owner
     * @dev Updates internal tracking after ownership transfer
     */
    function transferBoxOwnership(address boxAddress, address newOwner) external {
        require(isRegisteredBox[boxAddress], "Box not registered");
        require(newOwner != address(0), "Invalid new owner");
        
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        
        // Transfer ownership
        box.transferOwnership(newOwner);
        
        // Update internal tracking
        userBoxes[newOwner].push(boxAddress);
        
        emit DepositBoxRegistered(boxAddress, newOwner);
    }
    
    /**
     * @notice Get box information
     * @param boxAddress Address of the deposit box
     * @return owner Owner address
     * @return balance Box balance
     * @return boxType Type of box
     */
    function getBoxInfo(address boxAddress) 
        external 
        view 
        returns (address owner, uint256 balance, string memory boxType) 
    {
        require(isRegisteredBox[boxAddress], "Box not registered");
        
        IDepositBox box = IDepositBox(boxAddress);
        owner = box.getOwner();
        balance = box.getBalance();
        boxType = box.getBoxType();
    }
    
    /**
     * @notice Deposit funds into a box through the manager
     * @param boxAddress Address of the deposit box
     * @dev Demonstrates contract-to-contract interaction with value transfer
     */
    function depositToBox(address boxAddress) external payable {
        require(isRegisteredBox[boxAddress], "Box not registered");
        require(msg.value > 0, "Must send ether");
        
        IDepositBox box = IDepositBox(boxAddress);
        box.deposit{value: msg.value}();
    }
}
