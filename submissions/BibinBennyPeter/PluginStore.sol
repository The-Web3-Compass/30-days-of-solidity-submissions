// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Profile {
    address public owner;
    
    struct UserProfile {
        string name;
        string avatar;
        bool exists;
    }
    
    mapping(address => UserProfile) public profiles;
    mapping(bytes4 => address) public registeredPlugins;
    mapping(address => mapping(bytes4 => bool)) public userPluginActivation;
    mapping(address => mapping(string => uint256)) public userNumbers;
    mapping(address => mapping(string => string)) public userStrings;
    
    event ProfileCreated(address indexed user, string name, string avatar);
    event ProfileUpdated(address indexed user, string name, string avatar);
    event PluginRegistered(bytes4 indexed selector, address indexed plugin);
    event PluginActivated(address indexed user, bytes4 indexed selector);
    event PluginDeactivated(address indexed user, bytes4 indexed selector);
    
    constructor() {
        owner = msg.sender;
    }
    
    function _isOwner() internal view returns (bool) {
        return msg.sender == owner;
    }
    
    function _hasProfile() internal view returns (bool) {
        return profiles[msg.sender].exists;
    }
    
    function createProfile(string memory _name, string memory _avatar) external {
        require(!profiles[msg.sender].exists, "Profile already exists");
        profiles[msg.sender] = UserProfile(_name, _avatar, true);
        emit ProfileCreated(msg.sender, _name, _avatar);
    }
    
    function updateProfile(string memory _name, string memory _avatar) external {
        require(_hasProfile(), "Profile does not exist");
        profiles[msg.sender].name = _name;
        profiles[msg.sender].avatar = _avatar;
        emit ProfileUpdated(msg.sender, _name, _avatar);
    }
    
    function registerPlugin(bytes4 _selector, address _plugin) external {
        require(_isOwner(), "Not owner");
        require(_plugin != address(0), "Invalid plugin address");
        registeredPlugins[_selector] = _plugin;
        emit PluginRegistered(_selector, _plugin);
    }
    
    function activatePlugin(bytes4 _selector) external {
        require(_hasProfile(), "Profile does not exist");
        require(registeredPlugins[_selector] != address(0), "Plugin not registered");
        userPluginActivation[msg.sender][_selector] = true;
        emit PluginActivated(msg.sender, _selector);
    }
    
    function deactivatePlugin(bytes4 _selector) external {
        require(_hasProfile(), "Profile does not exist");
        userPluginActivation[msg.sender][_selector] = false;
        emit PluginDeactivated(msg.sender, _selector);
    }
    
    function isPluginActivated(address _user, bytes4 _selector) external view returns (bool) {
        return userPluginActivation[_user][_selector];
    }
    
    function setUserNumber(string memory _key, uint256 _value) external {
        userNumbers[msg.sender][_key] = _value;
    }
    
    function getUserNumber(string memory _key) external view returns (uint256) {
        return userNumbers[msg.sender][_key];
    }
    
    function setUserString(string memory _key, string memory _value) external {
        userStrings[msg.sender][_key] = _value;
    }
    
    function getUserString(string memory _key) external view returns (string memory) {
        return userStrings[msg.sender][_key];
    }
    
    fallback() external payable {
        bytes4 selector = bytes4(msg.data);
        address plugin = registeredPlugins[selector];
        
        require(plugin != address(0), "Plugin not registered");
        require(_hasProfile(), "Profile does not exist");
        require(userPluginActivation[msg.sender][selector], "Plugin not activated");
        
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), plugin, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

contract InventoryPlugin {
    function addItem(uint256 _id, string memory _name, uint256 _quantity) external {
        Profile(address(this)).setUserNumber(string(abi.encodePacked("item_", _id, "_qty")), _quantity);
        Profile(address(this)).setUserString(string(abi.encodePacked("item_", _id, "_name")), _name);
    }
    
    function getItemQuantity(uint256 _id) external view returns (uint256) {
        return Profile(address(this)).getUserNumber(string(abi.encodePacked("item_", _id, "_qty")));
    }
    
    function getItemName(uint256 _id) external view returns (string memory) {
        return Profile(address(this)).getUserString(string(abi.encodePacked("item_", _id, "_name")));
    }
    
    function removeItem(uint256 _id) external {
        Profile(address(this)).setUserNumber(string(abi.encodePacked("item_", _id, "_qty")), 0);
        Profile(address(this)).setUserString(string(abi.encodePacked("item_", _id, "_name")), "");
    }
}

contract StatisticsPlugin {
    function setLevel(uint256 _level) external {
        Profile(address(this)).setUserNumber("level", _level);
    }
    
    function getLevel() external view returns (uint256) {
        return Profile(address(this)).getUserNumber("level");
    }
    
    function setExperience(uint256 _experience) external {
        Profile(address(this)).setUserNumber("exp", _experience);
    }
    
    function getExperience() external view returns (uint256) {
        return Profile(address(this)).getUserNumber("exp");
    }
    
    function addScore(uint256 _points) external {
        uint256 currentScore = Profile(address(this)).getUserNumber("score");
        Profile(address(this)).setUserNumber("score", currentScore + _points);
    }
    
    function getScore() external view returns (uint256) {
        return Profile(address(this)).getUserNumber("score");
    }
}

contract AchievementPlugin {
    function unlockAchievement(string memory _achievement) external {
        Profile(address(this)).setUserNumber(_achievement, 1);
    }
    
    function hasAchievement(string memory _achievement) external view returns (bool) {
        return Profile(address(this)).getUserNumber(_achievement) == 1;
    }
    
    function revokeAchievement(string memory _achievement) external {
        Profile(address(this)).setUserNumber(_achievement, 0);
    }
}
