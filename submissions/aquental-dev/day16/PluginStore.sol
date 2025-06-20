// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for plugins to ensure consistent interaction with the core contract
interface IPlugin {
    // Initializes the plugin for a specific player
    function initialize(address player) external;
    // Executes a plugin-specific action, returning success and data
    function execute(
        address player,
        bytes calldata data
    ) external returns (bool success, bytes memory result);
}

// Library for safe delegatecall operations
library SafeDelegateCall {
    // Performs a delegatecall and checks for success, reverting with error if it fails
    function safeDelegate(
        address target,
        bytes memory data
    ) internal returns (bool success, bytes memory result) {
        (success, result) = target.delegatecall(data);
        require(success, "Delegatecall failed");
    }
}

// Core contract for managing player profiles and plugins
contract PluginStore {
    // Struct to store player profile data
    struct PlayerProfile {
        string name; // Player's display name
        string avatar; // Player's avatar URL or hash
        mapping(address => bool) activePlugins; // Tracks activated plugins
    }

    // Mapping of player addresses to their profiles
    mapping(address => PlayerProfile) private profiles;

    // Mapping of plugin addresses to their initialization status
    mapping(address => bool) private registeredPlugins;

    // Event emitted when a plugin is registered
    event PluginRegistered(address indexed plugin);
    // Event emitted when a plugin is activated for a player
    event PluginActivated(address indexed player, address indexed plugin);
    // Event emitted when a plugin is deactivated for a player
    event PluginDeactivated(address indexed player, address indexed plugin);
    // Event emitted when a player's profile is updated
    event ProfileUpdated(address indexed player, string name, string avatar);

    // Modifier to ensure only registered plugins are used
    modifier onlyRegisteredPlugin(address plugin) {
        require(registeredPlugins[plugin], "Plugin not registered");
        _;
    }

    // Modifier to ensure the caller is a valid player with a profile
    modifier onlyValidPlayer() {
        require(
            bytes(profiles[msg.sender].name).length > 0,
            "Profile not initialized"
        );
        _;
    }

    // Initializes a player's profile with a name and avatar
    function initializeProfile(
        string calldata name,
        string calldata avatar
    ) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(
            bytes(profiles[msg.sender].name).length == 0,
            "Profile already initialized"
        );

        profiles[msg.sender].name = name;
        profiles[msg.sender].avatar = avatar;
        emit ProfileUpdated(msg.sender, name, avatar);
    }

    // Updates a player's profile name and avatar
    function updateProfile(
        string calldata name,
        string calldata avatar
    ) external onlyValidPlayer {
        require(bytes(name).length > 0, "Name cannot be empty");

        profiles[msg.sender].name = name;
        profiles[msg.sender].avatar = avatar;
        emit ProfileUpdated(msg.sender, name, avatar);
    }

    // Registers a new plugin contract
    function registerPlugin(address plugin) external {
        require(plugin != address(0), "Invalid plugin address");
        require(!registeredPlugins[plugin], "Plugin already registered");

        registeredPlugins[plugin] = true;
        emit PluginRegistered(plugin);
    }

    // Activates a plugin for the caller
    function activatePlugin(
        address plugin
    ) external onlyValidPlayer onlyRegisteredPlugin(plugin) {
        require(
            !profiles[msg.sender].activePlugins[plugin],
            "Plugin already active"
        );

        profiles[msg.sender].activePlugins[plugin] = true;

        // Initialize the plugin using delegatecall
        bytes memory data = abi.encodeWithSelector(
            IPlugin.initialize.selector,
            msg.sender
        );
        (bool success, ) = SafeDelegateCall.safeDelegate(plugin, data);
        require(success, "Plugin initialization failed");

        emit PluginActivated(msg.sender, plugin);
    }

    // Deactivates a plugin for the caller
    function deactivatePlugin(
        address plugin
    ) external onlyValidPlayer onlyRegisteredPlugin(plugin) {
        require(
            profiles[msg.sender].activePlugins[plugin],
            "Plugin not active"
        );

        profiles[msg.sender].activePlugins[plugin] = false;
        emit PluginDeactivated(msg.sender, plugin);
    }

    // Executes a plugin action using delegatecall
    function executePlugin(
        address plugin,
        bytes calldata data
    )
        external
        onlyValidPlayer
        onlyRegisteredPlugin(plugin)
        returns (bytes memory)
    {
        require(
            profiles[msg.sender].activePlugins[plugin],
            "Plugin not active"
        );

        // Execute plugin logic using delegatecall
        (, bytes memory result) = SafeDelegateCall.safeDelegate(plugin, data);
        return result;
    }

    // Retrieves a player's profile data
    function getProfile(
        address player
    )
        external
        view
        returns (
            string memory name,
            string memory avatar,
            address[] memory activePlugins
        )
    {
        PlayerProfile storage profile = profiles[player];
        require(bytes(profile.name).length > 0, "Profile not found");

        // Count active plugins
        uint256 count = 0;
        for (uint256 i = 0; i < count; i++) {
            if (profile.activePlugins[address(uint160(i))]) {
                count++;
            }
        }

        // Populate active plugins array
        activePlugins = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < count; i++) {
            if (profile.activePlugins[address(uint160(i))]) {
                activePlugins[index] = address(uint160(i));
                index++;
            }
        }

        return (profile.name, profile.avatar, activePlugins);
    }

    // Checks if a plugin is active for a player
    function isPluginActive(
        address player,
        address plugin
    ) external view onlyRegisteredPlugin(plugin) returns (bool) {
        return profiles[player].activePlugins[plugin];
    }
}

// Example plugin contract for achievements
contract AchievementPlugin is IPlugin {
    // Struct to store achievement data
    struct Achievement {
        string title;
        bool unlocked;
    }

    // Mapping of player addresses to their achievements
    mapping(address => Achievement[]) private achievements;

    // Event emitted when an achievement is unlocked
    event AchievementUnlocked(address indexed player, string title);

    // Initializes the plugin for a player
    function initialize(address player) external override {
        // Initialize with a default achievement
        achievements[player].push(Achievement("First Login", false));
    }

    // Executes an achievement-related action
    function execute(
        address player,
        bytes calldata data
    ) external override returns (bool success, bytes memory result) {
        // Decode the action (e.g., unlock achievement)
        (string memory action, uint256 achievementId) = abi.decode(
            data,
            (string, uint256)
        );

        if (keccak256(bytes(action)) == keccak256(bytes("unlockAchievement"))) {
            require(
                achievementId < achievements[player].length,
                "Invalid achievement ID"
            );
            require(
                !achievements[player][achievementId].unlocked,
                "Achievement already unlocked"
            );

            achievements[player][achievementId].unlocked = true;
            emit AchievementUnlocked(
                player,
                achievements[player][achievementId].title
            );
            return (true, abi.encode(achievements[player][achievementId]));
        }

        return (false, abi.encode("Unknown action"));
    }
}
