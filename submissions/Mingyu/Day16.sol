// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    // Mapping to store the player's profile (name, avatar)
    mapping(address => PlayerProfile) public profiles;

    // Multi-plugin support: mapping plugin name (key) to plugin contract address
    mapping(string => address) public plugins;

    // ========== Core Profile Logic ==========

    /**
     * @dev Set the player's profile (name and avatar)
     * @param _name Player's name
     * @param _avatar Player's avatar URL
     */
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    /**
     * @dev Get the player's profile by address
     * @param user Player's address
     * @return name Player's name
     * @return avatar Player's avatar URL
     */
    function getProfile(address user) external view returns (string memory, string memory) {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // ========== Plugin Management ==========

    /**
     * @dev Register a new plugin by providing its contract address
     * @param key Unique plugin identifier (e.g., "achievements", "inventory")
     * @param pluginAddress Address of the plugin contract
     */
    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    /**
     * @dev Get a registered plugin's address
     * @param key Unique plugin identifier
     * @return Plugin contract address
     */
    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // ========== Plugin Execution ==========

    /**
     * @dev Execute a plugin function that modifies the blockchain state
     * @param key Unique plugin identifier
     * @param functionSignature The function signature to call (e.g., "updateAchievements(address,uint256)")
     * @param user The user address to execute the plugin for
     * @param argument The arguments to pass to the plugin function
     */
    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        // Encoding the function signature with the parameters to call
        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);

        // Call the plugin contract
        (bool success, ) = plugin.call(data);
        require(success, "Plugin execution failed");
    }

    /**
     * @dev Execute a plugin function that only reads data (view function)
     * @param key Unique plugin identifier
     * @param functionSignature The function signature to call (e.g., "getAchievements(address)")
     * @param user The user address to execute the plugin for
     * @return The result of the view call (decoded as string)
     */
    function runPluginView(
        string memory key,
        string memory functionSignature,
        address user
    ) external view returns (string memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        // Encoding the function signature with the parameters to call
        bytes memory data = abi.encodeWithSignature(functionSignature, user);

        // Call the plugin contract in a view mode (staticcall)
        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin view call failed");

        // Decode the result and return it
        return abi.decode(result, (string));
    }
}
