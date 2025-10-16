// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlugin.sol";

contract AchievementPlugin is IPlugin {
    string public constant PLUGIN_NAME = "Achievement System";
    uint256 public constant PLUGIN_VERSION = 1;

    struct Achievement {
        string name;
        string description;
        uint256 pointsReward;
        bool isSecret;
    }

    mapping(uint256 => Achievement) public achievements;
    uint256 public totalAchievements;

    event AchievementUnlocked(address indexed player, uint256 indexed achievementId, string name);
    
    constructor() {
        achievements[1] = Achievement("First Steps", "Create your first profile", 100, false);
        achievements[2] = Achievement("Social Butterfly", "Activate 3 different plugins", 250, false);
        achievements[3] = Achievement("Veteran", "Play for 30 days", 500, false);
        achievements[4] = Achievement("Secret Master", "Unlock all secret achievements", 1000, true);
        totalAchievements = 4;
    }
    
    function getPluginName() external pure override returns (string memory) {
        return PLUGIN_NAME;
    }
    
    function getPluginVersion() external pure override returns (uint256) {
        return PLUGIN_VERSION;
    }
    
    function getRequiredStorageSlots() external pure override returns (uint256) {
        return 10; 
    }
    
    function isCompatible(uint256 coreVersion) external pure override returns (bool) {
        return coreVersion >= 1; 
    }
    
    function initialize(address player) external override {
        _setPlayerAchievementPoints(player, 0);
        _setPlayerAchievementCount(player, 0);
        
        _unlockAchievement(player, 1);
    }
    
    function execute(bytes calldata data) external override returns (bytes memory) {
        bytes4 selector = bytes4(data[:4]);
        
        if (selector == this.unlockAchievement.selector) {
            (address player, uint256 achievementId) = abi.decode(data[4:], (address, uint256));
            _unlockAchievement(player, achievementId);
            return abi.encode(true);
        }
        
        if (selector == this.getPlayerAchievements.selector) {
            (address player) = abi.decode(data[4:], (address));
            return abi.encode(_getPlayerAchievementData(player));
        }
        
        if (selector == this.checkAchievementProgress.selector) {
            (address player) = abi.decode(data[4:], (address));
            _checkAndUnlockAchievements(player);
            return abi.encode(true);
        }
        
        revert("AchievementPlugin: unknown function selector");
    }
    
    
    function unlockAchievement(address player, uint256 achievementId) external {
        _unlockAchievement(player, achievementId);
    }
    
    function getPlayerAchievements(address player) external view returns (
        uint256 totalPoints,
        uint256 achievementCount,
        uint256[] memory unlockedAchievements
    ) {
        return _getPlayerAchievementData(player);
    }
    
    function checkAchievementProgress(address player) external {
        _checkAndUnlockAchievements(player);
    }

    function _unlockAchievement(address player, uint256 achievementId) internal {
        require(achievementId > 0 && achievementId <= totalAchievements, "Invalid achievement ID");

        string memory unlockKey = string(abi.encodePacked("unlocked_", _toString(achievementId)));
        bool alreadyUnlocked = _getPlayerBool(player, unlockKey);
        require(!alreadyUnlocked, "Achievement already unlocked");

        _setPlayerBool(player, unlockKey, true);

        Achievement memory achievement = achievements[achievementId];
        uint256 currentPoints = _getPlayerAchievementPoints(player);
        uint256 currentCount = _getPlayerAchievementCount(player);
        
        _setPlayerAchievementPoints(player, currentPoints + achievement.pointsReward);
        _setPlayerAchievementCount(player, currentCount + 1);
        
        emit AchievementUnlocked(player, achievementId, achievement.name);
    }
    
    function _checkAndUnlockAchievements(address player) internal {
        
        uint256 pluginCount = _getPlayerUint(player, "active_plugin_count");
        if (pluginCount >= 3) {
            string memory unlockKey = "unlocked_2";
            if (!_getPlayerBool(player, unlockKey)) {
                _unlockAchievement(player, 2);
            }
        }

        uint256 joinTime = _getPlayerUint(player, "join_timestamp");
        if (block.timestamp >= joinTime + 30 days) {
            string memory unlockKey = "unlocked_3";
            if (!_getPlayerBool(player, unlockKey)) {
                _unlockAchievement(player, 3);
            }
        }
    }
    
    function _getPlayerAchievementData(address player) internal view returns (
        uint256 totalPoints,
        uint256 achievementCount,
        uint256[] memory unlockedAchievements
    ) {
        totalPoints = _getPlayerAchievementPoints(player);
        achievementCount = _getPlayerAchievementCount(player);

        uint256[] memory tempUnlocked = new uint256[](totalAchievements);
        uint256 unlockedCount = 0;
        
        for (uint256 i = 1; i <= totalAchievements; i++) {
            string memory unlockKey = string(abi.encodePacked("unlocked_", _toString(i)));
            if (_getPlayerBool(player, unlockKey)) {
                tempUnlocked[unlockedCount] = i;
                unlockedCount++;
            }
        }
        
        unlockedAchievements = new uint256[](unlockedCount);
        for (uint256 i = 0; i < unlockedCount; i++) {
            unlockedAchievements[i] = tempUnlocked[i];
        }
    }
    
    
    function _setPlayerAchievementPoints(address player, uint256 points) internal {
        _setPlayerUint(player, "achievement_points", points);
    }
    
    function _getPlayerAchievementPoints(address player) internal view returns (uint256) {
        return _getPlayerUint(player, "achievement_points");
    }
    
    function _setPlayerAchievementCount(address player, uint256 count) internal {
        _setPlayerUint(player, "achievement_count", count);
    }
    
    function _getPlayerAchievementCount(address player) internal view returns (uint256) {
        return _getPlayerUint(player, "achievement_count");
    }
    
    function _setPlayerUint(address player, string memory key, uint256 value) internal {
        (bool success,) = address(this).call(
            abi.encodeWithSignature("setPluginUint(string,uint256)", key, value)
        );
        require(success, "Failed to set uint storage");
    }
    
    function _getPlayerUint(address player, string memory key) internal view returns (uint256) {
        (bool success, bytes memory data) = address(this).staticcall(
            abi.encodeWithSignature("getPluginUint(string)", key)
        );
        require(success, "Failed to get uint storage");
        return abi.decode(data, (uint256));
    }
    
    function _setPlayerBool(address player, string memory key, bool value) internal {
        (bool success,) = address(this).call(
            abi.encodeWithSignature("setPluginBool(string,bool)", key, value)
        );
        require(success, "Failed to set bool storage");
    }
    
    function _getPlayerBool(address player, string memory key) internal view returns (bool) {
        (bool success, bytes memory data) = address(this).staticcall(
            abi.encodeWithSignature("getPluginBool(string)", key)
        );
        require(success, "Failed to get bool storage");
        return abi.decode(data, (bool));
    }
    
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
