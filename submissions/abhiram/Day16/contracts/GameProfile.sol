// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../libraries/ProfileLib.sol";
import "../libraries/DelegatecallLib.sol";
import "./IPlugin.sol";

/**
 * @title GameProfile
 * @dev Core profile contract for Web3 game players
 * 
 * This contract demonstrates the power of delegatecall and modular architecture:
 * 
 * 1. CORE STORAGE: Each player has a profile with name, avatar, and plugin list
 * 2. PLUGINS: Additional features (achievements, inventory, etc.) are separate contracts
 * 3. DELEGATECALL: Plugins execute code that reads/writes to the profile's storage
 * 4. MODULARITY: Add new features without redeploying the main contract
 * 
 * KEY CONCEPT: delegatecall means plugins run with the profile contract's storage,
 * but the profile contract doesn't need to know each plugin's implementation details.
 */
contract GameProfile {
    using ProfileLib for string;
    using DelegatecallLib for address;

    // ============ Storage ============
    
    struct Profile {
        string name;
        string avatarURI;
        uint256 createdAt;
        bool exists;
    }

    // Player address => Profile
    mapping(address => Profile) public profiles;

    // Player address => List of enabled plugins
    mapping(address => address[]) public enabledPlugins;

    // Player address => Plugin address => Is enabled
    mapping(address => mapping(address => bool)) public isPluginEnabled;

    // ============ Events ============

    event ProfileCreated(address indexed player, string name, string avatar);
    event ProfileUpdated(address indexed player, string name, string avatar);
    event PluginEnabled(address indexed player, address indexed plugin);
    event PluginDisabled(address indexed player, address indexed plugin);
    event PluginCalled(address indexed player, address indexed plugin, string functionSignature);

    // ============ Errors ============

    error ProfileDoesNotExist(address player);
    error ProfileAlreadyExists(address player);
    error PluginAlreadyEnabled(address player, address plugin);
    error PluginNotEnabled(address player, address plugin);
    error InvalidPluginAddress(address plugin);
    error DelegatecallExecutionFailed(string reason);

    // ============ Modifiers ============

    /**
     * @dev Ensures the caller has a profile
     */
    modifier onlyProfileOwner() {
        if (!profiles[msg.sender].exists) {
            revert ProfileDoesNotExist(msg.sender);
        }
        _;
    }

    // ============ Core Functions ============

    /**
     * @dev Creates a new profile for the caller
     * 
     * @param _name The player's display name
     * @param _avatarURI The URI to the player's avatar image
     */
    function createProfile(string calldata _name, string calldata _avatarURI) external {
        if (profiles[msg.sender].exists) {
            revert ProfileAlreadyExists(msg.sender);
        }

        ProfileLib.validateProfileName(_name);
        ProfileLib.validateAvatarURI(_avatarURI);

        profiles[msg.sender] = Profile({
            name: _name,
            avatarURI: _avatarURI,
            createdAt: block.timestamp,
            exists: true
        });

        emit ProfileCreated(msg.sender, _name, _avatarURI);
    }

    /**
     * @dev Updates an existing profile
     * 
     * @param _name The new display name
     * @param _avatarURI The new avatar URI
     */
    function updateProfile(string calldata _name, string calldata _avatarURI) external onlyProfileOwner {
        ProfileLib.validateProfileName(_name);
        ProfileLib.validateAvatarURI(_avatarURI);

        profiles[msg.sender].name = _name;
        profiles[msg.sender].avatarURI = _avatarURI;

        emit ProfileUpdated(msg.sender, _name, _avatarURI);
    }

    /**
     * @dev Gets the player's profile
     * 
     * @param _player The player's address
     * @return The profile struct containing name, avatar, and creation time
     */
    function getProfile(address _player) external view returns (Profile memory) {
        if (!profiles[_player].exists) {
            revert ProfileDoesNotExist(_player);
        }
        return profiles[_player];
    }

    // ============ Plugin Management ============

    /**
     * @dev Enables a plugin for the player's profile
     * 
     * IMPORTANT: This only registers the plugin. It doesn't copy code or storage.
     * Plugins are separate contracts that use delegatecall to interact with the profile.
     * 
     * @param _plugin The address of the plugin contract
     */
    function enablePlugin(address _plugin) external onlyProfileOwner {
        ProfileLib.validatePluginAddress(_plugin);

        if (isPluginEnabled[msg.sender][_plugin]) {
            revert PluginAlreadyEnabled(msg.sender, _plugin);
        }

        // Verify the plugin implements IPlugin interface
        try IPlugin(_plugin).name() {} catch {
            revert InvalidPluginAddress(_plugin);
        }

        isPluginEnabled[msg.sender][_plugin] = true;
        enabledPlugins[msg.sender].push(_plugin);

        emit PluginEnabled(msg.sender, _plugin);
    }

    /**
     * @dev Disables a plugin for the player's profile
     * 
     * @param _plugin The address of the plugin contract
     */
    function disablePlugin(address _plugin) external onlyProfileOwner {
        if (!isPluginEnabled[msg.sender][_plugin]) {
            revert PluginNotEnabled(msg.sender, _plugin);
        }

        isPluginEnabled[msg.sender][_plugin] = false;

        // Remove from array
        address[] storage plugins = enabledPlugins[msg.sender];
        for (uint256 i = 0; i < plugins.length; i++) {
            if (plugins[i] == _plugin) {
                plugins[i] = plugins[plugins.length - 1];
                plugins.pop();
                break;
            }
        }

        emit PluginDisabled(msg.sender, _plugin);
    }

    /**
     * @dev Gets all enabled plugins for a player
     * 
     * @param _player The player's address
     * @return Array of enabled plugin addresses
     */
    function getEnabledPlugins(address _player) external view returns (address[] memory) {
        return enabledPlugins[_player];
    }

    // ============ Plugin Execution (The Heart of delegatecall) ============

    /**
     * @dev Executes a plugin function using delegatecall
     * 
     * THIS IS THE KEY CONCEPT:
     * - delegatecall executes the plugin's code
     * - BUT with the GameProfile contract's storage context
     * - This means plugins can read/write to the profile data
     * - Without plugins needing to be part of this contract
     * 
     * Example: achievementPlugin.addAchievement("Boss Slayer")
     * - Runs the achievement logic from the plugin
     * - But stores achievement data in GameProfile's storage
     * - All while keeping msg.sender and msg.value intact
     * 
     * @param _plugin The plugin contract address
     * @param _functionSignature The function to call (e.g., "addAchievement(string)")
     * @param _params The encoded parameters for the function
     */
    function executePluginFunction(
        address _plugin,
        string calldata _functionSignature,
        bytes calldata _params
    ) external onlyProfileOwner returns (bytes memory) {
        if (!isPluginEnabled[msg.sender][_plugin]) {
            revert PluginNotEnabled(msg.sender, _plugin);
        }

        // Encode the function call
        bytes4 selector = DelegatecallLib.getSelector(_functionSignature);
        bytes memory callData = DelegatecallLib.encodeCall(selector, _params);

        // Execute with delegatecall
        // This is the magic: the plugin code runs, but in our storage context
        (bool success, bytes memory result) = _plugin.delegatecall(callData);

        if (!success) {
            if (result.length > 0) {
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            }
            revert DelegatecallExecutionFailed("Unknown error during plugin execution");
        }

        emit PluginCalled(msg.sender, _plugin, _functionSignature);
        return result;
    }

    /**
     * @dev Helper to execute plugin function with simple parameters
     * 
     * This is a more ergonomic way to call simple plugin functions
     * 
     * @param _plugin The plugin contract address
     * @param _functionSignature The function signature
     */
    function executePluginFunctionSimple(
        address _plugin,
        string calldata _functionSignature
    ) external onlyProfileOwner returns (bytes memory) {
        return executePluginFunction(_plugin, _functionSignature, "");
    }
}
