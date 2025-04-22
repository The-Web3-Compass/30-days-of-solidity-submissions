// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PluginStoreDelegate
 * @notice Core profile store for a Web3 game using delegatecall to execute modular plugins
 * @dev All plugin logic executes in the context of this contract's storage
 */
contract PluginStoreDelegate {
    // ======== Storage Layout ========

    // Profile data: each player's basic info lives in core storage
    struct PlayerProfile {
        string name;
        string avatar;
    }
    mapping(address => PlayerProfile) public profiles;

    // Registry of plugin implementations by key
    mapping(string => address) public plugins;

    // Optional per-plugin data storage: users can store bytes-encoded state per plugin
    // Plugins must agree on how to encode/decode into this mapping
    mapping(address => mapping(string => bytes)) public pluginData;

    // Owner for plugin registration
    address public owner;

    // ======== Events ========
    event PluginRegistered(string indexed key, address implementation);
    event ProfileUpdated(address indexed user, string name, string avatar);

    // ======== Constructor ========
    constructor() {
        owner = msg.sender;
    }

    // ======== Modifiers ========
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ======== Profile Logic (unchanged) ========

    /**
     * @notice Set or update the caller's basic profile
     */
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
        emit ProfileUpdated(msg.sender, _name, _avatar);
    }

    /**
     * @notice Register or upgrade a plugin implementation
     * @param key   Unique identifier for the plugin
     * @param impl  Address of the plugin contract
     */
    function registerPlugin(string calldata key, address impl) external onlyOwner {
        require(impl != address(0), "Invalid plugin address");
        plugins[key] = impl;
        emit PluginRegistered(key, impl);
    }

    // ======== Delegatecall Execution ========

    /**
     * @notice Execute a state-changing plugin function in core storage via delegatecall
     * @param key                Plugin key identifying which implementation to invoke
     * @param functionSignature  ABI signature of the plugin function (e.g. "doAction(address,bytes)")
     * @param args               ABI-encoded arguments for the plugin function
     * @return returnData        ABI-encoded return from plugin
     * @dev Plugins operate on this contract's storage, including pluginData mapping
     */
    function runPlugin(
        string calldata key,
        string calldata functionSignature,
        bytes calldata args
    ) external payable returns (bytes memory returnData) {
        address impl = plugins[key];
        require(impl != address(0), "Plugin not registered");

        // Prepare the call data: selector + args
        bytes memory data = abi.encodePacked(
            bytes4(keccak256(bytes(functionSignature))),
            args
        );

        // delegatecall into the plugin, using this contract's storage and msg.sender
        (bool success, bytes memory out) = impl.delegatecall(data);
        require(success, "Plugin delegatecall failed");
        return out;
    }

    /**
     * @notice Execute a view-only plugin function via delegatecall
     * @dev Uses staticcall to prevent state changes
     */
    function runPluginView(
        string calldata key,
        string calldata functionSignature,
        bytes calldata args
    ) external view returns (bytes memory returnData) {
        address impl = plugins[key];
        require(impl != address(0), "Plugin not registered");

        bytes memory data = abi.encodePacked(
            bytes4(keccak256(bytes(functionSignature))),
            args
        );

        (bool success, bytes memory out) = impl.staticcall(data);
        require(success, "Plugin staticcall failed");
        return out;
    }

    // ======== Fallback ========
    fallback() external payable {
        revert("Use runPlugin or runPluginView");
    }
}