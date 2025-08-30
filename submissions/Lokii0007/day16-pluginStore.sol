// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract PluginStore {
    struct PlayerProfile{
        string name;
        string avatar;
    }
    mapping(address => PlayerProfile) public profiles;
    mapping(string => address) public plugins;

    function setProfile(string memory _name, string memory _avatar) external{
       profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address _user)public view returns(string memory, string memory) {
        return (profiles[_user].name, profiles[_user].avatar);
    }

    function registerPlugin(string memory _key, address _pluginAddress) external {
        plugins[_key] = _pluginAddress;
    }

    function getPlugin(string memory _key) public view returns(address) {
        return plugins[_key];
    }

    function runPlugin(string memory _key, address _user, string memory _functionSignature, string memory _argument) external {
        address plugin = plugins[_key];
        require(plugin != address(0), "no plugin found");
        require(_user != address(0), "invalid user address");

        bytes memory data = abi.encodeWithSignature(_functionSignature, _user, _argument);
        (bool success, ) = plugin.call(data);

        require(success, "plugin addon failed");
    }

    function runPluginView(string memory _key, address _user, string memory _functionSignature) external view returns(string memory){
        address plugin = plugins[_key];
        require(plugin != address(0), "no plugin found");
        require(_user != address(0), "invalid user address");

        bytes memory data = abi.encodeWithSignature(_functionSignature, _user);
        (bool success, bytes memory result) = plugin.staticcall(data);

        require(success, "plugin addon failed");
        return abi.decode(result, (string));
    }
}

//* pluginstore.runplugin("weapon", "setWeapon(address,string)", msg.sender, "m416" )