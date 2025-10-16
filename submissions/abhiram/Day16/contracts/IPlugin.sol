// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IPlugin
 * @dev Interface for all plugin contracts
 * 
 * All plugins must implement this interface to ensure consistent
 * integration with the GameProfile contract. The version() function
 * helps track plugin compatibility.
 */
interface IPlugin {
    /**
     * @dev Returns the plugin version
     * @return The version string (e.g., "1.0.0")
     */
    function version() external pure returns (string memory);

    /**
     * @dev Returns the plugin name
     * @return The name of the plugin
     */
    function name() external pure returns (string memory);
}
