// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./contracts/GameProfile.sol";
import "./contracts/IPlugin.sol";
import "./plugins/AchievementsPlugin.sol";
import "./plugins/InventoryPlugin.sol";
import "./plugins/BattleStatsPlugin.sol";
import "./plugins/SocialPlugin.sol";

/**
 * @title PluginStore
 * @dev Factory and registry for managing game profile plugins
 * 
 * This contract serves as a central hub for deploying and managing plugins
 * for the GameProfile system. Players can discover, deploy, and manage plugins
 * for their profiles through this contract.
 * 
 * This demonstrates how the modular architecture can be extended with
 * a plugin discovery and management layer.
 */
contract PluginStore {
    // ============ Storage ============

    // Official plugins deployed by the game
    address public achievementsPlugin;
    address public inventoryPlugin;
    address public battleStatsPlugin;
    address public socialPlugin;

    // Track community plugins
    mapping(address => bool) public isOfficialPlugin;
    address[] public officialPlugins;

    mapping(address => Plugin) public communityPlugins;
    address[] public communityPluginList;

    struct Plugin {
        address author;
        string name;
        string description;
        string version;
        uint256 deployedAt;
        uint256 downloads;
        bool approved;
    }

    // ============ Events ============

    event OfficialPluginDeployed(address indexed plugin, string name, string version);
    event CommunityPluginSubmitted(address indexed plugin, address indexed author, string name);
    event CommunityPluginApproved(address indexed plugin);
    event PluginDownloaded(address indexed plugin, address indexed player);

    // ============ Errors ============

    error PluginAlreadyDeployed(address plugin);
    error InvalidPluginAddress(address plugin);
    error PluginNotApproved(address plugin);

    // ============ Constructor ============

    /**
     * @dev Deploys the official plugins
     */
    constructor() {
        // Deploy official plugins
        achievementsPlugin = address(new AchievementsPlugin());
        inventoryPlugin = address(new InventoryPlugin());
        battleStatsPlugin = address(new BattleStatsPlugin());
        socialPlugin = address(new SocialPlugin());

        // Register official plugins
        _registerOfficialPlugin(achievementsPlugin, "Achievements", "1.0.0");
        _registerOfficialPlugin(inventoryPlugin, "Inventory", "1.0.0");
        _registerOfficialPlugin(battleStatsPlugin, "Battle Stats", "1.0.0");
        _registerOfficialPlugin(socialPlugin, "Social", "1.0.0");
    }

    // ============ Official Plugin Functions ============

    /**
     * @dev Internal helper to register official plugins
     * 
     * @param _plugin The plugin address
     * @param _name The plugin name
     * @param _version The plugin version
     */
    function _registerOfficialPlugin(
        address _plugin,
        string memory _name,
        string memory _version
    ) internal {
        isOfficialPlugin[_plugin] = true;
        officialPlugins.push(_plugin);

        emit OfficialPluginDeployed(_plugin, _name, _version);
    }

    /**
     * @dev Gets all official plugins
     * 
     * @return Array of official plugin addresses
     */
    function getOfficialPlugins() external view returns (address[] memory) {
        return officialPlugins;
    }

    // ============ Community Plugin Functions ============

    /**
     * @dev Submits a community-created plugin for approval
     * 
     * This allows anyone to contribute plugins to the ecosystem.
     * Plugins must be approved by governance before being available.
     * 
     * @param _plugin The plugin contract address
     * @param _name The plugin name
     * @param _description The plugin description
     */
    function submitCommunityPlugin(
        address _plugin,
        string calldata _name,
        string calldata _description
    ) external {
        require(_plugin != address(0), "Invalid plugin address");
        require(bytes(_name).length > 0, "Name required");
        require(bytes(_description).length <= 500, "Description too long");

        if (communityPlugins[_plugin].author != address(0)) {
            revert PluginAlreadyDeployed(_plugin);
        }

        // Verify it implements IPlugin
        try IPlugin(_plugin).name() {} catch {
            revert InvalidPluginAddress(_plugin);
        }

        communityPlugins[_plugin] = Plugin({
            author: msg.sender,
            name: _name,
            description: _description,
            version: "1.0.0",
            deployedAt: block.timestamp,
            downloads: 0,
            approved: false
        });

        communityPluginList.push(_plugin);

        emit CommunityPluginSubmitted(_plugin, msg.sender, _name);
    }

    /**
     * @dev Approves a community plugin (governance function)
     * 
     * @param _plugin The plugin to approve
     */
    function approveCommunityPlugin(address _plugin) external {
        // In production, this would have proper governance/admin checks
        require(_plugin != address(0), "Invalid plugin");
        require(communityPlugins[_plugin].author != address(0), "Plugin not found");
        require(!communityPlugins[_plugin].approved, "Already approved");

        communityPlugins[_plugin].approved = true;

        emit CommunityPluginApproved(_plugin);
    }

    /**
     * @dev Gets all community plugins
     * 
     * @return Array of community plugin addresses
     */
    function getCommunityPlugins() external view returns (address[] memory) {
        return communityPluginList;
    }

    /**
     * @dev Gets plugin information
     * 
     * @param _plugin The plugin address
     * @return Plugin information if it's a community plugin
     */
    function getPluginInfo(address _plugin) external view returns (Plugin memory) {
        return communityPlugins[_plugin];
    }

    /**
     * @dev Records a plugin download/installation
     * 
     * Called when a player enables a plugin
     * 
     * @param _plugin The plugin being installed
     */
    function recordPluginDownload(address _plugin) external {
        if (!isOfficialPlugin[_plugin] && !communityPlugins[_plugin].approved) {
            revert PluginNotApproved(_plugin);
        }

        if (isOfficialPlugin[_plugin]) {
            // Count downloads for official plugin
        } else {
            communityPlugins[_plugin].downloads++;
        }

        emit PluginDownloaded(_plugin, msg.sender);
    }

    // ============ Helper Functions ============

    /**
     * @dev Checks if a plugin is available
     * 
     * @param _plugin The plugin address
     * @return Whether the plugin is official or approved community plugin
     */
    function isAvailablePlugin(address _plugin) external view returns (bool) {
        return isOfficialPlugin[_plugin] || communityPlugins[_plugin].approved;
    }
}