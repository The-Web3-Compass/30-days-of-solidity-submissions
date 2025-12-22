// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
  ProfileStorage library: Defines the data structures shared between the main contract and plugins, and provides access functions.
  It uses a fixed storage slot (keccak("game.profile.storage.v1")) to avoid slot conflicts between the plugin and other variables in the main contract.
*/
library ProfileStorage {
    // Data structure for each player (extendable)
    struct Player {
        string name;
        string avatar;
        // Stores whether a plugin is active (pluginId -> bool)
        mapping(bytes32 => bool) activePlugins;
        // Private uint storage for plugins (pluginKey -> uint)
        mapping(bytes32 => uint256) pluginUints;
        // You can continue to extend more types (mapping / arrays, etc.)
    }

    // Global storage: players mapping + plugin registry
    struct Storage {
        mapping(address => Player) players;          // key: player address
        mapping(bytes32 => address) pluginRegistry;  // pluginId -> implementation address
        address admin;                               // Admin (can register plugins)
    }

    // Fixed slot, both plugins and the main contract access the storage here
    bytes32 internal constant STORAGE_SLOT = keccak256("game.profile.storage.v1");

    // Returns storage pointer (storage pointer pattern)
    function s() internal pure returns (Storage storage ds) {
        bytes32 slot = STORAGE_SLOT;
        assembly { ds.slot := slot }
    }

    // Helper: Set/Read player name
    function setName(address player, string memory name) internal {
        s().players[player].name = name;
    }
    function getName(address player) internal view returns (string memory) {
        return s().players[player].name;
    }

    // Helper: Set/Read avatar
    function setAvatar(address player, string memory avatar) internal {
        s().players[player].avatar = avatar;
    }
    function getAvatar(address player) internal view returns (string memory) {
        return s().players[player].avatar;
    }

    // Activate/Deactivate plugin
    function setPluginActive(address player, bytes32 pluginId, bool active) internal {
        s().players[player].activePlugins[pluginId] = active;
    }
    function isPluginActive(address player, bytes32 pluginId) internal view returns (bool) {
        return s().players[player].activePlugins[pluginId];
    }

    // Plugin uint access (example: achievement count, etc.)
    function setPluginUint(address player, bytes32 key, uint256 val) internal {
        s().players[player].pluginUints[key] = val;
    }
    function getPluginUint(address player, bytes32 key) internal view returns (uint256) {
        return s().players[player].pluginUints[key];
    }

    // Manage plugin registry (only admin can operate)
    function registerPlugin(bytes32 pluginId, address impl) internal {
        s().pluginRegistry[pluginId] = impl;
    }
    function pluginImplementation(bytes32 pluginId) internal view returns (address) {
        return s().pluginRegistry[pluginId];
    }

    // Admin settings/reads
    function setAdmin(address admin_) internal {
        s().admin = admin_;
    }
    function getAdmin() internal view returns (address) {
        return s().admin;
    }
}

/*
  CoreProfile contract — Main contract (the only contract deployed on the chain)
  - Stores basic player information (name, avatar)
  - Manages plugin registration (admin)
  - Allows players to activate plugins (pluginId activated to their personal profile)
  - Executes plugin logic via delegatecall (plugin must be in the registry)
*/
contract CoreProfile {
    // Import library, actually no data is stored in the library, just call the library functions (library functions access the fixed slot)
    using ProfileStorage for *;

    // Set the admin during construction
    constructor() {
        ProfileStorage.setAdmin(msg.sender);
    }

    // ========== Basic Profile API ==========
    function setName(string memory name) external {
        // Write msg.sender's name into storage (ProfileStorage's fixed slot)
        ProfileStorage.setName(msg.sender, name);
    }

    function setAvatar(string memory avatar) external {
        ProfileStorage.setAvatar(msg.sender, avatar);
    }

    function getName(address player) external view returns (string memory) {
        return ProfileStorage.getName(player);
    }

    function getAvatar(address player) external view returns (string memory) {
        return ProfileStorage.getAvatar(player);
    }

    // ========== Manage plugins (only admin) ==========
    modifier onlyAdmin() {
        require(msg.sender == ProfileStorage.getAdmin(), "Not admin");
        _;
    }

    // Admin registers the plugin implementation address to the pluginId
    function registerPlugin(bytes32 pluginId, address impl) external onlyAdmin {
        require(impl != address(0), "impl 0");
        ProfileStorage.registerPlugin(pluginId, impl);
    }

    // Query plugin implementation address
    function getPluginImplementation(bytes32 pluginId) external view returns (address) {
        return ProfileStorage.pluginImplementation(pluginId);
    }

    // ========== Player activates/deactivates plugin ==========
    // Player actively activates a plugin (it must be registered by admin first)
    function activatePlugin(bytes32 pluginId) external {
        address impl = ProfileStorage.pluginImplementation(pluginId);
        require(impl != address(0), "plugin not registered");
        ProfileStorage.setPluginActive(msg.sender, pluginId, true);
    }

    function deactivatePlugin(bytes32 pluginId) external {
        ProfileStorage.setPluginActive(msg.sender, pluginId, false);
    }

    function isPluginActive(address player, bytes32 pluginId) external view returns (bool) {
        return ProfileStorage.isPluginActive(player, pluginId);
    }

    // ========== Execute plugin logic via delegatecall ==========
    /*
      executePlugin:
        - pluginId: Identifier (registered by admin) -> Get implementation address
        - data: Call data (such as method selector + encoded parameters)
      Constraints and security points:
        - Only registered plugin implementation addresses are allowed to be called
        - Only allowed when the player has activated the corresponding pluginId
        - delegatecall will execute the plugin code in the storage context of this contract (CoreProfile)
    */
    function executePlugin(bytes32 pluginId, bytes calldata data) external payable returns (bytes memory) {
        address impl = ProfileStorage.pluginImplementation(pluginId);
        require(impl != address(0), "plugin not registered");
        require(ProfileStorage.isPluginActive(msg.sender, pluginId), "plugin not active for player");

        // delegatecall: Execute the code of impl on the current contract (CoreProfile) storage
        (bool ok, bytes memory ret) = impl.delegatecall(data);

        // Bubble up revert message if any
        require(ok, _getRevertMsg(ret));
        return ret;
    }

    // Helper: Decode revert reason
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return "delegatecall failed";
        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}

/*
  Example Plugin: AchievementPlugin
  - The plugin assumes the main contract uses ProfileStorage's fixed slot (the library above)
  - The plugin is deployed as a regular contract, but its logic is executed in CoreProfile via delegatecall
  - All reads and writes to ProfileStorage inside the plugin will actually take effect on CoreProfile's storage
*/
contract AchievementPlugin {
    // The plugin also uses ProfileStorage, so the compiled code will generate the same storage access code (reading from the same slot)
    using ProfileStorage for *;

    // The plugin provides a public function: Increment achievement count for the caller (msg.sender)
    // Note: When called via CoreProfile.delegatecall(), the plugin still sees msg.sender as the external address that initiated the transaction (the player), which is a feature of delegatecall.
    function addAchievement(bytes32 achievementKey) external {
        // Example key: keccak256("achiev:level1")
        // Get the old value and increment by 1
        uint256 old = ProfileStorage.getPluginUint(msg.sender, achievementKey);
        ProfileStorage.setPluginUint(msg.sender, achievementKey, old + 1);
    }

    // Read the achievement count (pure view function)
    function getAchievement(address player, bytes32 achievementKey) external view returns (uint256) {
        return ProfileStorage.getPluginUint(player, achievementKey);
    }

    // The plugin can have its own initialization function (if needed)
    // Note: If you want to initialize through delegatecall on Core, design it carefully to allow only admin or at specific times
    function initializeFor(address player) external {
        // For example, set some default values on the first run
        if (ProfileStorage.getPluginUint(player, keccak256("achiev:init")) == 0) {
            ProfileStorage.setPluginUint(player, keccak256("achiev:init"), 1);
        }
    }
}
