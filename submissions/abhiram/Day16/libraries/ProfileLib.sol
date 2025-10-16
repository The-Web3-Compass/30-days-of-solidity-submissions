// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ProfileLib
 * @dev Library for profile-related utilities and validations
 * 
 * This library provides common functionality for profile management,
 * including validation functions and event definitions that multiple
 * contracts can use.
 */
library ProfileLib {
    /// Events
    event PluginEnabled(address indexed player, address indexed pluginAddress);
    event PluginDisabled(address indexed player, address indexed pluginAddress);
    event ProfileUpdated(address indexed player, string name, string avatar);
    event PluginCalled(address indexed player, address indexed plugin, string functionName);

    /// Error definitions
    error InvalidProfileName(string reason);
    error InvalidAvatarURI(string reason);
    error InvalidPluginAddress(string reason);
    error UnauthorizedCaller(address caller, address owner);

    /**
     * @dev Validates a profile name
     * @param name The name to validate
     */
    function validateProfileName(string memory name) internal pure {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 50, "Name too long (max 50 chars)");
    }

    /**
     * @dev Validates an avatar URI
     * @param avatarURI The URI to validate
     */
    function validateAvatarURI(string memory avatarURI) internal pure {
        require(bytes(avatarURI).length <= 200, "Avatar URI too long");
    }

    /**
     * @dev Validates a plugin address is not zero
     * @param pluginAddress The address to validate
     */
    function validatePluginAddress(address pluginAddress) internal pure {
        require(pluginAddress != address(0), "Plugin address cannot be zero");
    }

    /**
     * @dev Validates caller is the profile owner
     * @param caller The caller's address
     * @param owner The owner's address
     */
    function validateOwner(address caller, address owner) internal pure {
        require(caller == owner, "Only owner can call this");
    }
}
