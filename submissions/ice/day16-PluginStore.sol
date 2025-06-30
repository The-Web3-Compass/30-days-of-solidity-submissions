// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PluginStore
 * @dev 支持模块化配置的种田游戏
 * 功能点：
 * 1. 核心合同存储每个玩家的基本个人资料（昵称）
 * 2. 玩家可以激活可选的"插件"来添加额外的功能
 * 3. 插件内容：(1)库存管理（土地面积，水量，肥料，种子）;
 * (2)种田管理（在已购资产中选择消耗 进行田园管理）；
 * (3)成就管理（展示用户等级和称号）;
 * (4)交易管理（用户默认有100游戏币初始。收成可以出售换取游戏币）
 * (5)好友列表
 * 每个插件都是一个单独的合约，有自己的逻辑，主合约使用 'delegatecall' 来执行插件函数，同时将所有数据保存在 core profile 中。
 * 允许开发人员添加或升级功能，而无需重新部署主合同
 */

// 插件接口
interface IPlugin {
    function initialize(address user) external returns (bool);
    function getPluginName() external pure returns (string memory);
    function getPluginVersion() external pure returns (uint256);
}

// 核心合约
contract PluginStore {
    address public owner;
    
    // 玩家基本资料
    struct PlayerProfile {
        string nickname;
        uint256 gameCoins;
        bool isRegistered;
        mapping(bytes32 => bool) activePlugins;
        
        // 库存管理数据
        uint256 landArea;
        uint256 waterAmount;
        uint256 fertilizerAmount;
        uint256 seedAmount;
        
        // 种田管理数据
        uint256 plantedSeeds;
        uint256 growthStage;
        uint256 lastHarvestTime;
        
        // 成就管理数据
        uint256 level;
        string title;
        uint256 experience;
        
        // 交易管理数据
        uint256 totalSales;
        uint256 totalPurchases;
        
        // 好友列表数据
        address[] friends;
        mapping(address => bool) isFriend;
    }
    
    // 存储所有玩家的资料
    mapping(address => PlayerProfile) private playerProfiles;
    
    // 注册的插件
    struct PluginInfo {
        address pluginAddress;
        string name;
        uint256 version;
        bool isActive;
    }
    
    mapping(bytes32 => PluginInfo) public plugins;
    bytes32[] public pluginKeys;
    
    // 事件
    event PlayerRegistered(address indexed player, string nickname);
    event PluginActivated(address indexed player, bytes32 pluginKey);
    event PluginDeactivated(address indexed player, bytes32 pluginKey);
    event PluginAdded(bytes32 indexed pluginKey, address pluginAddress);
    event PluginUpgraded(bytes32 indexed pluginKey, address newPluginAddress, uint256 newVersion);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegistered() {
        require(playerProfiles[msg.sender].isRegistered, "Player not registered");
        _;
    }
    
    // 注册新玩家
    function registerPlayer(string memory nickname) external {
        require(!playerProfiles[msg.sender].isRegistered, "Player already registered");
        
        PlayerProfile storage profile = playerProfiles[msg.sender];
        profile.nickname = nickname;
        profile.gameCoins = 100; // 初始游戏币
        profile.isRegistered = true;
        
        emit PlayerRegistered(msg.sender, nickname);
    }
    
    // 添加新插件
    function addPlugin(bytes32 pluginKey, address pluginAddress) external onlyOwner {
        require(plugins[pluginKey].pluginAddress == address(0), "Plugin already exists");
        
        IPlugin plugin = IPlugin(pluginAddress);
        
        plugins[pluginKey] = PluginInfo({
            pluginAddress: pluginAddress,
            name: plugin.getPluginName(),
            version: plugin.getPluginVersion(),
            isActive: true
        });
        
        pluginKeys.push(pluginKey);
        
        emit PluginAdded(pluginKey, pluginAddress);
    }
    
    // 升级插件
    function upgradePlugin(bytes32 pluginKey, address newPluginAddress) external onlyOwner {
        require(plugins[pluginKey].pluginAddress != address(0), "Plugin does not exist");
        
        IPlugin plugin = IPlugin(newPluginAddress);
        uint256 newVersion = plugin.getPluginVersion();
        
        require(newVersion > plugins[pluginKey].version, "New version must be higher than current version");
        
        plugins[pluginKey].pluginAddress = newPluginAddress;
        plugins[pluginKey].version = newVersion;
        
        emit PluginUpgraded(pluginKey, newPluginAddress, newVersion);
    }
    
    // 激活插件
    function activatePlugin(bytes32 pluginKey) external onlyRegistered {
        require(plugins[pluginKey].isActive, "Plugin not available");
        require(!playerProfiles[msg.sender].activePlugins[pluginKey], "Plugin already activated");
        
        IPlugin plugin = IPlugin(plugins[pluginKey].pluginAddress);
        bool success = plugin.initialize(msg.sender);
        require(success, "Plugin initialization failed");
        
        playerProfiles[msg.sender].activePlugins[pluginKey] = true;
        
        emit PluginActivated(msg.sender, pluginKey);
    }
    
    // 停用插件
    function deactivatePlugin(bytes32 pluginKey) external onlyRegistered {
        require(playerProfiles[msg.sender].activePlugins[pluginKey], "Plugin not activated");
        
        playerProfiles[msg.sender].activePlugins[pluginKey] = false;
        
        emit PluginDeactivated(msg.sender, pluginKey);
    }
    
    // 执行插件功能
    function executePlugin(bytes32 pluginKey, bytes calldata data) external onlyRegistered returns (bool, bytes memory) {
        require(playerProfiles[msg.sender].activePlugins[pluginKey], "Plugin not activated");
        
        address pluginAddr = plugins[pluginKey].pluginAddress;
        require(pluginAddr != address(0), "Plugin does not exist");
        
        (bool success, bytes memory result) = pluginAddr.delegatecall(data);
        return (success, result);
    }
    
    // 获取玩家信息
    function getPlayerProfile(address player) external view returns (
        string memory nickname,
        uint256 gameCoins,
        bool isRegistered,
        uint256 level,
        string memory title
    ) {
        PlayerProfile storage profile = playerProfiles[player];
        return (
            profile.nickname,
            profile.gameCoins,
            profile.isRegistered,
            profile.level,
            profile.title
        );
    }
    
    // 检查插件是否激活
    function isPluginActive(address player, bytes32 pluginKey) external view returns (bool) {
        return playerProfiles[player].activePlugins[pluginKey];
    }
    
    // 获取所有插件
    function getAllPlugins() external view returns (bytes32[] memory) {
        return pluginKeys;
    }
}

// 库存管理插件
contract InventoryPlugin is IPlugin {
    bytes32 public constant PLUGIN_KEY = keccak256("INVENTORY_PLUGIN");
    
    // 存储布局必须与主合约一致
    struct PlayerProfile {
        string nickname;
        uint256 gameCoins;
        bool isRegistered;
        mapping(bytes32 => bool) activePlugins;
        
        // 库存管理数据
        uint256 landArea;
        uint256 waterAmount;
        uint256 fertilizerAmount;
        uint256 seedAmount;
        
        // 种田管理数据
        uint256 plantedSeeds;
        uint256 growthStage;
        uint256 lastHarvestTime;
        
        // 成就管理数据
        uint256 level;
        string title;
        uint256 experience;
        
        // 交易管理数据
        uint256 totalSales;
        uint256 totalPurchases;
        
        // 好友列表数据
        address[] friends;
        mapping(address => bool) isFriend;
    }
    
    // 存储玩家资料的映射
    mapping(address => PlayerProfile) private playerProfiles;
    
    function initialize(address user) external override returns (bool) {
        // 初始化库存，可以在这里设置默认值
        return true;
    }
    
    function getPluginName() external pure override returns (string memory) {
        return "Inventory Management";
    }
    
    function getPluginVersion() external pure override returns (uint256) {
        return 1;
    }
    
    // 购买土地
    function buyLand(uint256 amount) external returns (bool) {
        PluginStore store = PluginStore(address(this));
        (, uint256 coins, , , ) = store.getPlayerProfile(msg.sender);
        
        uint256 price = amount * 10; // 每单位土地10游戏币
        require(coins >= price, "Insufficient game coins");
        
        // 更新玩家资料中的土地面积和游戏币
        // 注意：这些更改会直接影响主合约中的存储，因为使用了delegatecall
        PlayerProfile storage profile = playerProfiles[msg.sender];
        profile.landArea += amount;
        profile.gameCoins -= price;
        
        return true;
    }
    
    // 购买水
    function buyWater(uint256 amount) external returns (bool) {
        PluginStore store = PluginStore(address(this));
        (, uint256 coins, , , ) = store.getPlayerProfile(msg.sender);
        
        uint256 price = amount * 2; // 每单位水2游戏币
        require(coins >= price, "Insufficient game coins");
        
        PlayerProfile storage profile = playerProfiles[msg.sender];
        profile.waterAmount += amount;
        profile.gameCoins -= price;
        
        return true;
    }
    
    // 购买肥料
    function buyFertilizer(uint256 amount) external returns (bool) {
        PluginStore store = PluginStore(address(this));
        (, uint256 coins, , , ) = store.getPlayerProfile(msg.sender);
        
        uint256 price = amount * 3; // 每单位肥料3游戏币
        require(coins >= price, "Insufficient game coins");
        
        PlayerProfile storage profile = playerProfiles[msg.sender];
        profile.fertilizerAmount += amount;
        profile.gameCoins -= price;
        
        return true;
    }
    
    // 购买种子
    function buySeeds(uint256 amount) external returns (bool) {
        PluginStore store = PluginStore(address(this));
        (, uint256 coins, , , ) = store.getPlayerProfile(msg.sender);
        
        uint256 price = amount * 5; // 每单位种子5游戏币
        require(coins >= price, "Insufficient game coins");
        
        PlayerProfile storage profile = playerProfiles[msg.sender];
        profile.seedAmount += amount;
        profile.gameCoins -= price;
        
        return true;
    }
    
    // 获取库存状态
    function getInventory() external view returns (uint256 land, uint256 water, uint256 fertilizer, uint256 seeds) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        return (profile.landArea, profile.waterAmount, profile.fertilizerAmount, profile.seedAmount);
    }
}

// 种田管理插件
contract FarmingPlugin is IPlugin {
    bytes32 public constant PLUGIN_KEY = keccak256("FARMING_PLUGIN");
    
    // 存储布局必须与主合约一致
    struct PlayerProfile {
        string nickname;
        uint256 gameCoins;
        bool isRegistered;
        mapping(bytes32 => bool) activePlugins;
        
        // 库存管理数据
        uint256 landArea;
        uint256 waterAmount;
        uint256 fertilizerAmount;
        uint256 seedAmount;
        
        // 种田管理数据
        uint256 plantedSeeds;
        uint256 growthStage;
        uint256 lastHarvestTime;
        
        // 成就管理数据
        uint256 level;
        string title;
        uint256 experience;
        
        // 交易管理数据
        uint256 totalSales;
        uint256 totalPurchases;
        
        // 好友列表数据
        address[] friends;
        mapping(address => bool) isFriend;
    }
    
    // 存储玩家资料的映射
    mapping(address => PlayerProfile) private playerProfiles;
    
    function initialize(address user) external override returns (bool) {
        return true;
    }
    
    function getPluginName() external pure override returns (string memory) {
        return "Farming Management";
    }
    
    function getPluginVersion() external pure override returns (uint256) {
        return 1;
    }
    
    // 种植作物
    function plantSeeds(uint256 amount) external returns (bool) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        require(profile.seedAmount >= amount, "Not enough seeds");
        require(profile.landArea >= amount, "Not enough land");
        
        profile.seedAmount -= amount;
        profile.plantedSeeds += amount;
        profile.growthStage = 0;
        
        return true;
    }
    
    // 浇水
    function waterCrops(uint256 amount) external returns (bool) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        require(profile.waterAmount >= amount, "Not enough water");
        require(profile.plantedSeeds > 0, "No crops planted");
        
        profile.waterAmount -= amount;
        profile.growthStage += 1;
        
        return true;
    }
    
    // 施肥
    function fertilizeCrops(uint256 amount) external returns (bool) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        require(profile.fertilizerAmount >= amount, "Not enough fertilizer");
        require(profile.plantedSeeds > 0, "No crops planted");
        
        profile.fertilizerAmount -= amount;
        profile.growthStage += 2;
        
        return true;
    }
    
    // 收获
    function harvest() external returns (uint256) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        require(profile.plantedSeeds > 0, "No crops planted");
        require(profile.growthStage >= 5, "Crops not mature yet");
        
        uint256 harvestAmount = profile.plantedSeeds * profile.growthStage / 5;
        
        profile.plantedSeeds = 0;
        profile.growthStage = 0;
        profile.lastHarvestTime = block.timestamp;
        
        // 更新经验和等级
        profile.experience += harvestAmount;
        if (profile.experience >= profile.level * 100) {
            profile.level += 1;
        }
        
        return harvestAmount;
    }
    
    // 获取种植状态
    function getFarmingStatus() external view returns (uint256 planted, uint256 growthStage, uint256 lastHarvest) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        return (profile.plantedSeeds, profile.growthStage, profile.lastHarvestTime);
    }
}

// 成就管理插件
contract AchievementPlugin is IPlugin {
    bytes32 public constant PLUGIN_KEY = keccak256("ACHIEVEMENT_PLUGIN");
    
    // 存储布局必须与主合约一致
    struct PlayerProfile {
        string nickname;
        uint256 gameCoins;
        bool isRegistered;
        mapping(bytes32 => bool) activePlugins;
        
        // 库存管理数据
        uint256 landArea;
        uint256 waterAmount;
        uint256 fertilizerAmount;
        uint256 seedAmount;
        
        // 种田管理数据
        uint256 plantedSeeds;
        uint256 growthStage;
        uint256 lastHarvestTime;
        
        // 成就管理数据
        uint256 level;
        string title;
        uint256 experience;
        
        // 交易管理数据
        uint256 totalSales;
        uint256 totalPurchases;
        
        // 好友列表数据
        address[] friends;
        mapping(address => bool) isFriend;
    }
    
    // 存储玩家资料的映射
    mapping(address => PlayerProfile) private playerProfiles;
    
    function initialize(address user) external override returns (bool) {
        PlayerProfile storage profile = playerProfiles[user];
        profile.level = 1;
        profile.title = "Novice Farmer"; // 新手农民
        return true;
    }
    
    function getPluginName() external pure override returns (string memory) {
        return "Achievement Management";
    }
    
    function getPluginVersion() external pure override returns (uint256) {
        return 1;
    }
    
    // 获取成就信息
    function getAchievements() external view returns (uint256 level, string memory title, uint256 experience) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        return (profile.level, profile.title, profile.experience);
    }
    
    // 更新称号
    function updateTitle() external returns (string memory) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        if (profile.level >= 10) {
            profile.title = "Farming Master"; // 农业大师
        } else if (profile.level >= 5) {
            profile.title = "Skilled Farmer"; // 熟练农民
        } else if (profile.level >= 3) {
            profile.title = "Experienced Farmer"; // 有经验的农民
        }
        
        return profile.title;
    }
}

// 交易管理插件
contract TradePlugin is IPlugin {
    bytes32 public constant PLUGIN_KEY = keccak256("TRADE_PLUGIN");
    
    // 存储布局必须与主合约一致
    struct PlayerProfile {
        string nickname;
        uint256 gameCoins;
        bool isRegistered;
        mapping(bytes32 => bool) activePlugins;
        
        // 库存管理数据
        uint256 landArea;
        uint256 waterAmount;
        uint256 fertilizerAmount;
        uint256 seedAmount;
        
        // 种田管理数据
        uint256 plantedSeeds;
        uint256 growthStage;
        uint256 lastHarvestTime;
        
        // 成就管理数据
        uint256 level;
        string title;
        uint256 experience;
        
        // 交易管理数据
        uint256 totalSales;
        uint256 totalPurchases;
        
        // 好友列表数据
        address[] friends;
        mapping(address => bool) isFriend;
    }
    
    // 存储玩家资料的映射
    mapping(address => PlayerProfile) private playerProfiles;
    
    function initialize(address user) external override returns (bool) {
        return true;
    }
    
    function getPluginName() external pure override returns (string memory) {
        return "Trade Management";
    }
    
    function getPluginVersion() external pure override returns (uint256) {
        return 1;
    }
    
    // 出售收成
    function sellHarvest(uint256 amount) external returns (uint256) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        uint256 price = amount * 8; // 每单位收成8游戏币
        profile.gameCoins += price;
        profile.totalSales += amount;
        
        return price;
    }
    
    // 获取交易历史
    function getTradeHistory() external view returns (uint256 totalSales, uint256 totalPurchases) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        return (profile.totalSales, profile.totalPurchases);
    }
}

// 好友管理插件
contract FriendPlugin is IPlugin {
    bytes32 public constant PLUGIN_KEY = keccak256("FRIEND_PLUGIN");
    
    // 存储布局必须与主合约一致
    struct PlayerProfile {
        string nickname;
        uint256 gameCoins;
        bool isRegistered;
        mapping(bytes32 => bool) activePlugins;
        
        // 库存管理数据
        uint256 landArea;
        uint256 waterAmount;
        uint256 fertilizerAmount;
        uint256 seedAmount;
        
        // 种田管理数据
        uint256 plantedSeeds;
        uint256 growthStage;
        uint256 lastHarvestTime;
        
        // 成就管理数据
        uint256 level;
        string title;
        uint256 experience;
        
        // 交易管理数据
        uint256 totalSales;
        uint256 totalPurchases;
        
        // 好友列表数据
        address[] friends;
        mapping(address => bool) isFriend;
    }
    
    // 存储玩家资料的映射
    mapping(address => PlayerProfile) private playerProfiles;
    
    function initialize(address user) external override returns (bool) {
        return true;
    }
    
    function getPluginName() external pure override returns (string memory) {
        return "Friend Management";
    }
    
    function getPluginVersion() external pure override returns (uint256) {
        return 1;
    }
    
    // 添加好友
    function addFriend(address friend) external returns (bool) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        require(!profile.isFriend[friend], "Already friends");
        require(friend != msg.sender, "Cannot add yourself as friend");
        
        profile.friends.push(friend);
        profile.isFriend[friend] = true;
        
        return true;
    }
    
    // 移除好友
    function removeFriend(address friend) external returns (bool) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        
        require(profile.isFriend[friend], "Not a friend");
        
        profile.isFriend[friend] = false;
        
        // 从数组中移除好友
        for (uint256 i = 0; i < profile.friends.length; i++) {
            if (profile.friends[i] == friend) {
                // 将最后一个元素移到当前位置，然后删除最后一个元素
                profile.friends[i] = profile.friends[profile.friends.length - 1];
                profile.friends.pop();
                break;
            }
        }
        
        return true;
    }
    
    // 获取好友列表
    function getFriends() external view returns (address[] memory) {
        PlayerProfile storage profile = playerProfiles[msg.sender];
        return profile.friends;
    }
}

