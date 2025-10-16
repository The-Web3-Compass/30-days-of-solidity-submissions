// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPlugin.sol";

contract CoreProfile {
    struct Profile {
        string name;
        string avatar;
        mapping(address => bool) activePlugins;
    }

    mapping(address => Profile) private profiles;
    mapping(string => address) public pluginRegistry;

    event ProfileCreated(address indexed user, string name, string avatar);
    event PluginRegistered(string name, address plugin);
    event PluginActivated(address indexed user, string plugin);
    event PluginExecuted(address indexed user, string plugin, bytes data);

    modifier onlyRegisteredPlugin(string memory _plugin) {
        require(pluginRegistry[_plugin] != address(0), "Plugin not registered");
        _;
    }

    function createProfile(string calldata _name, string calldata _avatar) external {
        Profile storage p = profiles[msg.sender];
        p.name = _name;
        p.avatar = _avatar;
        emit ProfileCreated(msg.sender, _name, _avatar);
    }

    function registerPlugin(string calldata _name, address _plugin) external {
        pluginRegistry[_name] = _plugin;
        emit PluginRegistered(_name, _plugin);
    }

    function activatePlugin(string calldata _pluginName)
        external
        onlyRegisteredPlugin(_pluginName)
    {
        Profile storage p = profiles[msg.sender];
        address pluginAddr = pluginRegistry[_pluginName];
        p.activePlugins[pluginAddr] = true;
        emit PluginActivated(msg.sender, _pluginName);
    }

    function executePlugin(string calldata _pluginName, bytes calldata data)
        external
        onlyRegisteredPlugin(_pluginName)
    {
        address pluginAddr = pluginRegistry[_pluginName];
        Profile storage p = profiles[msg.sender];
        require(p.activePlugins[pluginAddr], "Plugin not active");

        // delegatecall executes plugin logic in core contract's context
        (bool success, ) = pluginAddr.delegatecall(
            abi.encodeWithSelector(IPlugin.execute.selector, data)
        );
        require(success, "Delegatecall failed");

        emit PluginExecuted(msg.sender, _pluginName, data);
    }

    function getProfile(address _user)
        external
        view
        returns (string memory name, string memory avatar)
    {
        Profile storage p = profiles[_user];
        return (p.name, p.avatar);
    }
}
