// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title PluginStore
 * @dev Build a modular profile system for a Web3 game.
 * The core contract stores each player's basic profile (like name and avatar),
 * but players can activate optional 'plugins' to add extra features like achievements,
 * inventory management, battle stats, or social interactions.
 * Each plugin is a separate contract with its own logic,
 * and the main contract uses `delegatecall` to execute plugin functions
 * while keeping all data in the core profile.
 * This allows developers to add or upgrade features without redeploying the main contract
 * — just like installing new add-ons in a game.
 * You'll learn how to use `delegatecall` safely, manage execution context,
 * and organize external logic in a modular way.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 16
 */
contract PluginStore {
    struct PlayerData {
        string name;
        bytes32 data;
    }

    mapping(address => PlayerData) players;
    mapping(string => address) plugins;

    // TODO add Ownable such that only owner can approve adding plugins
    function addPlugin(string memory pluginName, address plugin) public {
        plugins[pluginName] = plugin;
    }

    // read-only access storage of this contract from plugin contract
    function pluginInvokeStaticCall(
        string memory pluginName,
        string memory funcSig,
        string memory args
    ) public view returns(bytes memory) {
        address plugin = plugins[pluginName];
        require(plugin != address(0x00), "no plugin with this name");
        bytes memory callData = abi.encodeWithSignature(funcSig, msg.sender, args);
        (bool callSuccess, bytes memory callResult) = plugin.staticcall(callData);
        require(callSuccess, "call failure");
        return callResult;
    }

    // read-write access storage of plugin contract from plugin contract
    function pluginInvokeCall(
        string memory pluginName,
        string memory funcSig,
        string memory args
    ) public {
        address plugin = plugins[pluginName];
        require(plugin != address(0x00), "no plugin with this name");
        bytes memory callData = abi.encodeWithSignature(funcSig, msg.sender, args);
        (bool callSuccess,) = plugin.call(callData);
        require(callSuccess, "call failure");
    }
    
    // read-write access storage of this contract from plugin contract
    function pluginInvokeDelegateCall(
        string memory pluginName,
        string memory funcSig,
        string memory args
    ) public {
        address plugin = plugins[pluginName];
        require(plugin != address(0x00), "no plugin with this name");
        bytes memory callData = abi.encodeWithSignature(funcSig, msg.sender, args);
        (bool callSuccess,) = plugin.delegatecall(callData);
        require(callSuccess, "call failure");
    }
}
