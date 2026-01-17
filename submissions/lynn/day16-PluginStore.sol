//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PluginStore {
    struct Profile {
        string name;
        string avatar;
    }

    mapping(address => Profile) public profiles;
    mapping(string => address) public plugins;

    function setProfile(string calldata _name, string calldata _avatar) external {
        profiles[msg.sender] = Profile(_name, _avatar);
    }

    function getProfile() external view returns(string memory, string memory) {
        Profile memory profile = profiles[msg.sender];
        return (profile.name, profile.avatar);
    }

    function registerPlugin(string calldata _pluginName, address _pluginAddress) external {
        plugins[_pluginName] = _pluginAddress;
    }

    function getPlugin(string calldata _pluginName) external view returns(address) {
        return plugins[_pluginName];
    }

    function runPlugin(
        string calldata _pluginName, 
        string calldata _funcSignatureString, 
        address _user, 
        string calldata _argument
    ) external {
        address plugin = plugins[_pluginName];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(_funcSignatureString, _user, _argument);
        (bool success, ) = plugin.call(data);
        require(success, "Plugin call failed");
    }

    function runPluginView(
        string calldata _pluginName, 
        string calldata _funcSignatureString, 
        address user
    ) external view returns(string memory) {
        address plugin = plugins[_pluginName];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(_funcSignatureString, user);
        (bool success, bytes memory returnData) = plugin.staticcall(data); // read-only
        require(success, "Plugin view call failed");
        return abi.decode(returnData, (string));

    }
}