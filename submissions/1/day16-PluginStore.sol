// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// All plugin logic executes in the context of this contract's storage
contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    mapping(address => PlayerProfile) public profiles;

    mapping(string => address) public plugins;

    //Events
    event PluginRegistered(string indexed key, address implementation);
    event ProfileUpdated(address indexed user, string name, string avatar);

    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
        emit ProfileUpdated(msg.sender, _name, _avatar);
    }

    function registerPlugin(
        string calldata key,
        address pluginAddress
    ) external {
        require(pluginAddress != address(0), "Invalid plugin address");
        plugins[key] = pluginAddress;
        emit PluginRegistered(key, pluginAddress);
    }

    //Delegatecall Execution

    function runPlugin(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external returns (bytes memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(
            functionSignature,
            user,
            argument
        );

        // delegatecall into the plugin, using this contract's storage and msg.sender
        (bool success, bytes memory result) = plugin.delegatecall(data);
        require(success, "Plugin delegatecall failed");
        return result;
    }

    //staticcall to prevent state changes
    function runPluginView(
        string calldata key,
        string calldata functionSignature,
        bytes calldata args
    ) external view returns (bytes memory) {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodePacked(
            bytes4(keccak256(bytes(functionSignature))),
            args
        );

        (bool success, bytes memory result) = plugin.staticcall(data);
        require(success, "Plugin staticcall failed");
        return result;
    }
}

contract WeaponPlugin {
    // This mapping will actually live in PluginStore's storage due to delegatecall
    mapping(address => string[]) internal weapon;

    function setWeapon(address player, string memory newWeapon) external {
        weapon[player].push(newWeapon);
    }

    function getWeapon(address player) external view returns (string[] memory) {
        return weapon[player];
    }
}

// Uses delegatecall so data is stored in PluginStore.
contract AchievementPlugin {
    mapping(address => string[]) internal Achievements;

    function setAchievement(
        address player,
        string memory achievement
    ) external {
        Achievements[player].push(achievement);
    }

    function getAchievements(
        address player
    ) external view returns (string[] memory) {
        return Achievements[player];
    }
}