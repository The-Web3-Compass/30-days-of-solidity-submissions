// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PlayerProfile
 * @author shivam
 * @notice Manages player profiles, plugin registration/activation, and delegates calls to active plugins.
 * @dev Core contract storing profile data. Uses delegatecall to execute plugin logic in its context.
 * Owner manages plugins; players manage their active plugins and profile data.
 * STORAGE LAYOUT WARNING:
 * This contract is designed to be used with plugins via delegatecall. It does NOT declare plugin-specific mappings (such as achievements or inventoryItems) directly.
 * Each plugin (e.g., AchievementsPlugin, InventoryPlugin) introduces its own storage variables (mappings) that will be stored in the next available storage slots of this contract when called via delegatecall.
 * To avoid storage collisions:
 *   - Do NOT add new state variables to this contract after deployment, unless you fully understand Solidity's storage layout rules.
 *   - DO NOT declare plugin-specific mappings (like achievements or inventoryItems) here. Leave those to the plugins.
 *   - If you upgrade this contract or add new plugins, manage storage slots carefully and document any changes.
 * As currently written, activating multiple plugins is SAFE and will NOT cause storage collision, as long as this contract does not declare the same mappings as the plugins.
 */
contract PlayerProfile {
    /**
     * @notice Struct storing basic profile data for a player.
     * @param name The player's chosen name.
     * @param avatarURI A URI pointing to the player's avatar image.
     */
    struct ProfileData {
        string name;
        string avatarURI;
    }

    /// @notice Address of the contract owner, responsible for plugin management.
    address public immutable owner;

    /// @notice Mapping from player address to their core profile data (struct ProfileData).
    mapping(address => ProfileData) public profiles;

    /// @notice Mapping from function selector (bytes4) to the registered plugin contract address.
    mapping(bytes4 => address) public plugins;

    /// @notice Mapping indicating active plugins for each player (playerAddress => pluginAddress => isActive).
    mapping(address => mapping(address => bool)) public activePlugins;

    /// @notice Emitted when a player's core profile is updated via `setProfile`.
    /// @param player Address of the player whose profile was updated.
    /// @param name New name set for the player.
    /// @param avatarURI New avatar URI set for the player.
    event ProfileUpdated(address indexed player, string name, string avatarURI);

    /// @notice Emitted when a new plugin is registered by the owner via `registerPlugin`.
    /// @param selector Function selector the plugin handles.
    /// @param pluginAddress Address of the registered plugin contract.
    event PluginRegistered(bytes4 indexed selector, address indexed pluginAddress);

    /// @notice Emitted when a plugin is unregistered by the owner via `unregisterPlugin`.
    /// @param selector Function selector that was unregistered.
    /// @param pluginAddress Address of the plugin contract that was unregistered.
    event PluginUnregistered(bytes4 indexed selector, address indexed pluginAddress);

    /// @notice Emitted when a player activates a plugin via `activatePlugin`.
    /// @param player Address of the player.
    /// @param pluginAddress Address of the activated plugin contract.
    event PluginActivated(address indexed player, address indexed pluginAddress);

    /// @notice Emitted when a player deactivates a plugin via `deactivatePlugin`.
    /// @param player Address of the player.
    /// @param pluginAddress Address of the deactivated plugin contract.
    event PluginDeactivated(address indexed player, address indexed pluginAddress);

    /// @notice Error thrown for operations restricted to the owner.
    error NotOwner();

    /// @notice Error thrown when attempting to register a selector that is already in use.
    /// @param selector The selector that caused the conflict.
    error SelectorAlreadyRegistered(bytes4 selector);

    /// @notice Error thrown when attempting to unregister a selector that is not registered.
    /// @param selector The selector that was not found.
    error SelectorNotRegistered(bytes4 selector);

    /// @notice Error thrown when attempting to register or activate/deactivate a plugin at the zero address.
    error ZeroAddressPlugin();

    /// @notice Error thrown when attempting to activate/deactivate a plugin address (indirectly checked in fallback).
    /// @param pluginAddress The address that is not a registered plugin for the called selector.
    error PluginNotRegistered(address pluginAddress);

    /// @notice Error thrown when a fallback call uses a selector not mapped to any registered plugin.
    /// @param selector The selector that was not found.
    error InvalidPluginSelector(bytes4 selector);

    /// @notice Error thrown when a player calls a plugin function they haven't activated.
    /// @param player The player attempting the call (msg.sender).
    /// @param pluginAddress The address of the plugin that is not active for the player.
    error PluginNotActive(address player, address pluginAddress);

    /// @notice Error thrown when the delegatecall to a plugin fails without a specific revert reason.
    /// @param pluginAddress The address of the plugin whose delegatecall failed.
    error PluginCallFailed(address pluginAddress);

    /// @notice Initializes the contract by setting the deployer as the owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Modifier to restrict function access to the contract owner.
    /// @dev Reverts with {NotOwner} if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    /**
     * @notice Updates the caller's profile name and avatar URI.
     * @param _name The new name for the player (msg.sender).
     * @param _avatarURI The new avatar URI for the player (msg.sender).
     * @dev Stores the data in the `profiles` mapping. Emits {ProfileUpdated} event.
     */
    function setProfile(string memory _name, string memory _avatarURI) external {
        profiles[msg.sender] = ProfileData({ name: _name, avatarURI: _avatarURI });
        emit ProfileUpdated(msg.sender, _name, _avatarURI);
    }

    /**
     * @notice Retrieves the profile data (name and avatar URI) for a given player address.
     * @param _player The address of the player whose profile to retrieve.
     * @return name The player's stored name.
     * @return avatarURI The player's stored avatar URI.
     * @dev Reads directly from the `profiles` mapping.
     */
    function getProfile(address _player) external view returns (string memory name, string memory avatarURI) {
        ProfileData storage profile = profiles[_player];
        return (profile.name, profile.avatarURI);
    }

    /**
     * @notice Registers a plugin contract address for a specific function selector (owner only).
     * @param _selector The function selector the plugin handles (e.g., `bytes4(keccak256("funcName(uint256)"))`).
     * @param _pluginAddress The address of the contract implementing the logic for this selector.
     * @dev Maps the selector to the plugin address in the `plugins` mapping. Emits {PluginRegistered} event.
     * @custom:error ZeroAddressPlugin if _pluginAddress is the zero address.
     * @custom:error SelectorAlreadyRegistered if _selector is already mapped to a non-zero address.
     */
    function registerPlugin(bytes4 _selector, address _pluginAddress) external onlyOwner {
        if (_pluginAddress == address(0)) {
            revert ZeroAddressPlugin();
        }
        if (plugins[_selector] != address(0)) {
            revert SelectorAlreadyRegistered(_selector);
        }
        plugins[_selector] = _pluginAddress;
        emit PluginRegistered(_selector, _pluginAddress);
    }

    /**
     * @notice Unregisters the plugin associated with a specific function selector (owner only).
     * @param _selector The function selector to unregister.
     * @dev Removes the mapping for the selector in the `plugins` mapping. Emits {PluginUnregistered} event.
     * @custom:error SelectorNotRegistered if _selector is not currently mapped to a non-zero address.
     */
    function unregisterPlugin(bytes4 _selector) external onlyOwner {
        address currentPlugin = plugins[_selector];
        if (currentPlugin == address(0)) {
            revert SelectorNotRegistered(_selector);
        }
        delete plugins[_selector]; // Sets the address back to zero
        emit PluginUnregistered(_selector, currentPlugin);
    }

    /**
     * @notice Activates a specific plugin contract address for the caller (msg.sender).
     * @param _pluginAddress The address of the plugin contract to activate.
     * @dev Sets the mapping `activePlugins[msg.sender][_pluginAddress]` to true. Emits {PluginActivated} event.
     * Does not check if the plugin is registered; activation allows future calls if it *becomes* registered.
     * @custom:error ZeroAddressPlugin if _pluginAddress is the zero address.
     */
    function activatePlugin(address _pluginAddress) external {
        // Note: We don't explicitly check if _pluginAddress is a registered plugin here.
        // The check occurs in the fallback function when a call is attempted.
        // This allows activating plugins even if their selectors haven't been registered yet,
        // or activating addresses that might handle multiple plugin roles.
        if (_pluginAddress == address(0)) {
             revert ZeroAddressPlugin(); // Prevent activating the zero address
        }
        activePlugins[msg.sender][_pluginAddress] = true;
        emit PluginActivated(msg.sender, _pluginAddress);
    }

    /**
     * @notice Deactivates a specific plugin contract address for the caller (msg.sender).
     * @param _pluginAddress The address of the plugin contract to deactivate.
     * @dev Sets the mapping `activePlugins[msg.sender][_pluginAddress]` to false (by deleting). Emits {PluginDeactivated} event.
     * @custom:error ZeroAddressPlugin if _pluginAddress is the zero address.
     */
    function deactivatePlugin(address _pluginAddress) external {
        // No need to check if it was previously active or registered.
        if (_pluginAddress == address(0)) {
             revert ZeroAddressPlugin(); // Prevent deactivating the zero address
        }
        delete activePlugins[msg.sender][_pluginAddress]; // Sets the boolean to false
        emit PluginDeactivated(msg.sender, _pluginAddress);
    }

    /**
     * @notice Executes a function on an active plugin via delegatecall.
     * @param _pluginAddress The address of the plugin contract to call. Must be active for the caller.
     * @param _data The ABI-encoded calldata for the function to execute on the plugin.
     * @return success Boolean indicating if the delegatecall succeeded.
     * @return returnData Bytes containing the data returned by the plugin call, if any.
     * @dev Performs a delegatecall to the specified plugin, preserving msg.sender and msg.value.
     * Requires the caller (msg.sender) to have activated the `_pluginAddress`.
     * @custom:error ZeroAddressPlugin if _pluginAddress is the zero address.
     * @custom:error PluginNotActive if the _pluginAddress is not active for msg.sender.
     * @custom:error PluginCallFailed if the delegatecall fails without a specific revert reason from the plugin.
     */
    function executePluginCall(address _pluginAddress, bytes calldata _data) external payable returns (bool success, bytes memory returnData) {
        if (_pluginAddress == address(0)) {
             revert ZeroAddressPlugin();
        }
        if (!activePlugins[msg.sender][_pluginAddress]) {
            revert PluginNotActive(msg.sender, _pluginAddress);
        }
        (success, returnData) = _pluginAddress.delegatecall(_data);

        // revert with a generic error only if the call failed *without* providing a reason
        if (!success && returnData.length == 0) {
            revert PluginCallFailed(_pluginAddress);
        }

        // Success status and return data are returned implicitly
    }
}