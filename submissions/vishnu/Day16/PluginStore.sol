// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlugin.sol";
import "./PluginStorage.sol";

contract PluginStore {
    using PluginStorage for PluginStorage.PluginData;
    

    struct PlayerProfile {
        string playerName;
        string avatar;
        uint256 level;
        uint256 experience;
        uint256 joinTimestamp;
        bool isActive;
        address[] activePlugins;
        mapping(address => bool) hasPlugin;
        mapping(address => uint256) pluginActivationTime;
    }
    
    address public owner;
    uint256 public constant CORE_VERSION = 1;
    uint256 public totalPlayers;
    

    mapping(address => PlayerProfile) public playerProfiles;
    mapping(address => PluginStorage.PluginData) public pluginStorage;
    mapping(address => bool) public approvedPlugins;
    mapping(string => address) public pluginRegistry; // name => address
    
    address[] public allApprovedPlugins;
    address[] public allPlayers;
    
    event ProfileCreated(address indexed player, string name, string avatar);
    event ProfileUpdated(address indexed player, string field, string newValue);
    event PluginActivated(address indexed player, address indexed plugin, string pluginName);
    event PluginDeactivated(address indexed player, address indexed plugin);
    event PluginApproved(address indexed plugin, string name);
    event PluginExecuted(address indexed player, address indexed plugin, bytes data, bytes result);
    event ExperienceGained(address indexed player, uint256 amount, uint256 newTotal);
    event LevelUp(address indexed player, uint256 newLevel);

    modifier onlyOwner() {
        require(msg.sender == owner, "PluginStore: caller is not the owner");
        _;
    }
    
    modifier onlyActivePlayer() {
        require(playerProfiles[msg.sender].isActive, "PluginStore: player not registered");
        _;
    }
    
    modifier onlyApprovedPlugin(address plugin) {
        require(approvedPlugins[plugin], "PluginStore: plugin not approved");
        _;
    }
    
    modifier onlyPlayerWithPlugin(address player, address plugin) {
        require(playerProfiles[player].hasPlugin[plugin], "PluginStore: player doesn't have plugin");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    

    function createProfile(string calldata playerName, string calldata avatar) external {
        require(bytes(playerName).length > 0, "PluginStore: name cannot be empty");
        require(!playerProfiles[msg.sender].isActive, "PluginStore: profile already exists");
        
        PlayerProfile storage profile = playerProfiles[msg.sender];
        profile.playerName = playerName;
        profile.avatar = avatar;
        profile.level = 1;
        profile.experience = 0;
        profile.joinTimestamp = block.timestamp;
        profile.isActive = true;
        
        allPlayers.push(msg.sender);
        totalPlayers++;
        
        emit ProfileCreated(msg.sender, playerName, avatar);
    }

    function updateProfile(string calldata newName, string calldata newAvatar) external onlyActivePlayer {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        if (bytes(newName).length > 0 && keccak256(bytes(newName)) != keccak256(bytes(profile.playerName))) {
            profile.playerName = newName;
            emit ProfileUpdated(msg.sender, "name", newName);
        }
        
        if (bytes(newAvatar).length > 0 && keccak256(bytes(newAvatar)) != keccak256(bytes(profile.avatar))) {
            profile.avatar = newAvatar;
            emit ProfileUpdated(msg.sender, "avatar", newAvatar);
        }
    }
    

    function addExperience(address player, uint256 amount) external onlyOwner {
        PlayerProfile storage profile = playerProfiles[player];
        require(profile.isActive, "PluginStore: player not active");
        
        profile.experience += amount;
        emit ExperienceGained(player, amount, profile.experience);

        uint256 newLevel = (profile.experience / 1000) + 1;
        if (newLevel > profile.level) {
            profile.level = newLevel;
            emit LevelUp(player, newLevel);
        }
    }
    
    function approvePlugin(address plugin, string calldata pluginName) external onlyOwner {
        require(plugin != address(0), "PluginStore: invalid plugin address");
        require(!approvedPlugins[plugin], "PluginStore: plugin already approved");
        
        try IPlugin(plugin).getPluginName() returns (string memory name) {
            require(bytes(name).length > 0, "PluginStore: invalid plugin name");
        } catch {
            revert("PluginStore: plugin doesn't implement IPlugin interface");
        }
        
        try IPlugin(plugin).isCompatible(CORE_VERSION) returns (bool compatible) {
            require(compatible, "PluginStore: plugin not compatible with core version");
        } catch {
            revert("PluginStore: plugin compatibility check failed");
        }
        
        approvedPlugins[plugin] = true;
        pluginRegistry[pluginName] = plugin;
        allApprovedPlugins.push(plugin);
        
        emit PluginApproved(plugin, pluginName);
    }
    

    function activatePlugin(address plugin) external onlyActivePlayer onlyApprovedPlugin(plugin) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        require(!profile.hasPlugin[plugin], "PluginStore: plugin already activated");
        
        try IPlugin(plugin).initialize(msg.sender) {
            profile.hasPlugin[plugin] = true;
            profile.activePlugins.push(plugin);
            profile.pluginActivationTime[plugin] = block.timestamp;
            
            string memory pluginName = IPlugin(plugin).getPluginName();
            emit PluginActivated(msg.sender, plugin, pluginName);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("PluginStore: plugin initialization failed - ", reason)));
        }
    }
    

    function deactivatePlugin(address plugin) external onlyActivePlayer onlyPlayerWithPlugin(msg.sender, plugin) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        profile.hasPlugin[plugin] = false;

        for (uint256 i = 0; i < profile.activePlugins.length; i++) {
            if (profile.activePlugins[i] == plugin) {
                profile.activePlugins[i] = profile.activePlugins[profile.activePlugins.length - 1];
                profile.activePlugins.pop();
                break;
            }
        }
        
        emit PluginDeactivated(msg.sender, plugin);
    }
    

    function executePlugin(address plugin, bytes calldata data) external onlyActivePlayer onlyPlayerWithPlugin(msg.sender, plugin) returns (bytes memory) {
        require(approvedPlugins[plugin], "PluginStore: plugin not approved");
        
        (bool success, bytes memory result) = plugin.delegatecall(
            abi.encodeWithSelector(IPlugin.execute.selector, data)
        );
        
        if (!success) {
            if (result.length > 0) {
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            } else {
                revert("PluginStore: plugin execution failed");
            }
        }
        
        emit PluginExecuted(msg.sender, plugin, data, result);
        return result;
    }
    

    function batchExecutePlugins(
        address[] calldata plugins,
        bytes[] calldata data
    ) external onlyActivePlayer returns (bytes[] memory results) {
        require(plugins.length == data.length, "PluginStore: arrays length mismatch");
        
        results = new bytes[](plugins.length);
        
        for (uint256 i = 0; i < plugins.length; i++) {
            require(playerProfiles[msg.sender].hasPlugin[plugins[i]], "PluginStore: player doesn't have plugin");
            require(approvedPlugins[plugins[i]], "PluginStore: plugin not approved");
            
            (bool success, bytes memory result) = plugins[i].delegatecall(
                abi.encodeWithSelector(IPlugin.execute.selector, data[i])
            );
            
            if (success) {
                results[i] = result;
                emit PluginExecuted(msg.sender, plugins[i], data[i], result);
            } else {
                results[i] = abi.encode("execution failed");
            }
        }
    }
    

    function setPluginUint(string memory key, uint256 value) external {
        pluginStorage[msg.sender].setUint(msg.sender, key, value);
    }
    
    function getPluginUint(string memory key) external view returns (uint256) {
        return pluginStorage[msg.sender].getUint(msg.sender, key);
    }
    
    function setPluginString(string memory key, string memory value) external {
        pluginStorage[msg.sender].setString(msg.sender, key, value);
    }
    
    function getPluginString(string memory key) external view returns (string memory) {
        return pluginStorage[msg.sender].getString(msg.sender, key);
    }
    
    function setPluginBool(string memory key, bool value) external {
        pluginStorage[msg.sender].setBool(msg.sender, key, value);
    }
    
    function getPluginBool(string memory key) external view returns (bool) {
        return pluginStorage[msg.sender].getBool(msg.sender, key);
    }
    

    function getPlayerProfile(address player) external view returns (
        string memory playerName,
        string memory avatar,
        uint256 level,
        uint256 experience,
        uint256 joinTimestamp,
        bool isActive,
        address[] memory activePlugins
    ) {
        PlayerProfile storage profile = playerProfiles[player];
        return (
            profile.playerName,
            profile.avatar,
            profile.level,
            profile.experience,
            profile.joinTimestamp,
            profile.isActive,
            profile.activePlugins
        );
    }

    function getPluginInfo(address plugin) external view returns (
        string memory name,
        uint256 version,
        bool isApproved,
        bool isCompatible
    ) {
        if (!approvedPlugins[plugin]) {
            return ("", 0, false, false);
        }
        
        try IPlugin(plugin).getPluginName() returns (string memory pluginName) {
            name = pluginName;
        } catch {
            name = "Unknown";
        }
        
        try IPlugin(plugin).getPluginVersion() returns (uint256 pluginVersion) {
            version = pluginVersion;
        } catch {
            version = 0;
        }
        
        try IPlugin(plugin).isCompatible(CORE_VERSION) returns (bool compatible) {
            isCompatible = compatible;
        } catch {
            isCompatible = false;
        }
        
        isApproved = approvedPlugins[plugin];
    }
    
    function getAllApprovedPlugins() external view returns (address[] memory) {
        return allApprovedPlugins;
    }

    function getAllPlayers() external view returns (address[] memory) {
        return allPlayers;
    }
    

    function hasPlugin(address player, address plugin) external view returns (bool) {
        return playerProfiles[player].hasPlugin[plugin];
    }
    
    function getPluginByName(string calldata name) external view returns (address) {
        return pluginRegistry[name];
    }
    

    function revokePlugin(address plugin) external onlyOwner {
        require(approvedPlugins[plugin], "PluginStore: plugin not approved");
        
        approvedPlugins[plugin] = false;
        
        for (uint256 i = 0; i < allApprovedPlugins.length; i++) {
            if (allApprovedPlugins[i] == plugin) {
                allApprovedPlugins[i] = allApprovedPlugins[allApprovedPlugins.length - 1];
                allApprovedPlugins.pop();
                break;
            }
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "PluginStore: new owner cannot be zero address");
        owner = newOwner;
    }
    
    function pauseNewRegistrations() external onlyOwner {
    
    }
}
