//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Build a lightweight core profile contract.
// Build a web3 game and modularize all the features and information.
contract PluginStore{
    struct PlayerProfile{
        string name;
        string avatar;
    }

    mapping(address=>PlayerProfile) public profiles;

    // Multi-plugin support
    mapping(string=>address) public plugins;

    function setProfile(string memory _name,string memory _avatar) external{
        profiles[msg.sender]=PlayerProfile(_name,_avatar);
    }

    function getProfile(address user) external view returns(string memory,string memory){
        PlayerProfile memory profile=profiles[user];
        return (profile.name,profile.avatar);
    }

    // Key can be the name of plugin.
    function registerPlugin(string memory key,address pluginAddress) external{
        plugins[key]=pluginAddress;
    }

    // Key can be the name of plugin.
    function getPlugin(string memory key) external view returns(address){
        return plugins[key];
    }

    function runPlugin(string memory key,string memory functionSignature,address user,string memory argument) external{
        address plugin=plugins[key];
        require(plugin!=address(0),"Plugin not registered");
        
        // "functionSignature" can be:
        // function setAchievement(address user,string memory achievement) public{
        // latesAchievement[user]=achievement;
        // }
        // Build a low-level function call from a string.
        bytes memory data=abi.encodeWithSignature(functionSignature,user,argument);
        // ".call":tell another contract to do something,that contract uses its own state and its own storage.
        // - Low-level `call` sends the request to the plugin contract.
        // - The plugin executes in **its own storage context**, **not** the PluginStore's.
        (bool success,)=plugin.call(data);
        require(success,"Plugin execution failed");

    }

    function runPluginView(string memory key,string memory functionSignature,address user) external view returns(string memory){
        address plugin=plugins[key];
        require(plugin!=address(0),"Plugin not registered");

        // "functionSignature" can be:
        // function getAchievement(address user) public view returns(string memory){
        // return latesAchievement[user];
        //     }  
        bytes memory data=abi.encodeWithSignature(functionSignature,user);
        // ".staticcall": like ".call" but read-only.
        (bool success, bytes memory result)=plugin.staticcall(data);
        require(success,"Plugin view call failed");
        // Converts the returned bytes into a string so we can return it to the caller.
        return abi.decode(result,(string));
    }
}

// ".delegatecall":borrow logic from another contract but running it in your contract's storage context.