// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PluginStore
 * @dev A modular Web3 profile system that supports optional feature plugins using delegatecall.
 */
contract PluginStore {
    struct Player {
        string name;
        string avatar;
        mapping(string => bool) installedPlugins;
    }

    mapping(address => Player) public players;
    mapping(string => address) public pluginAddresses;

    /// @notice Register or update a plugin contract
    function registerPlugin(string memory pluginName, address pluginAddress) external {
        pluginAddresses[pluginName] = pluginAddress;
    }

    /// @notice Create a new player profile
    function createProfile(string memory _name, string memory _avatar) external {
        Player storage player = players[msg.sender];
        player.name = _name;
        player.avatar = _avatar;
    }

    /// @notice Execute a plugin function using delegatecall
    function executePlugin(string memory pluginName, bytes memory data)
        external
        returns (bytes memory)
    {
        address pluginAddress = pluginAddresses[pluginName];
        require(pluginAddress != address(0), "Plugin not registered");

        (bool success, bytes memory result) = pluginAddress.delegatecall(data);
        require(success, "Plugin execution failed");

        return result;
    }

    /// @notice Retrieve a player's basic profile details
    function getProfile(address playerAddr)
        external
        view
        returns (string memory, string memory)
    {
        Player storage player = players[playerAddr];
        return (player.name, player.avatar);
    }
}
