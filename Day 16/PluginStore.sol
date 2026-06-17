// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//  Interface for plugins
interface IPlugin {
    function execute(bytes calldata data) external;
}

//  Core contract that stores profile data and supports plugins
contract PluginStore {
    struct Profile {
        string name;
        string avatar;
        mapping(address => bool) activePlugins; // track installed plugins
    }

    mapping(address => Profile) private profiles;

    event PluginExecuted(address indexed user, address indexed plugin);
    event PluginActivated(address indexed user, address indexed plugin);

    // Create or update a player profile
    function setProfile(string calldata _name, string calldata _avatar) external {
        profiles[msg.sender].name = _name;
        profiles[msg.sender].avatar = _avatar;
    }

    // Install a plugin
    function activatePlugin(address _plugin) external {
        profiles[msg.sender].activePlugins[_plugin] = true;
        emit PluginActivated(msg.sender, _plugin);
    }

    // Execute plugin code via delegatecall (runs in this contract's context)
    function usePlugin(address _plugin, bytes calldata _data) external {
        require(profiles[msg.sender].activePlugins[_plugin], "Plugin not active");

        // Safe delegatecall
        (bool success, ) = _plugin.delegatecall(
            abi.encodeWithSignature("execute(bytes)", _data)
        );
        require(success, "Plugin execution failed");

        emit PluginExecuted(msg.sender, _plugin);
    }

    // View profile info
    function getProfile(address user) external view returns (string memory, string memory) {
        Profile storage p = profiles[user];
        return (p.name, p.avatar);
    }
}
