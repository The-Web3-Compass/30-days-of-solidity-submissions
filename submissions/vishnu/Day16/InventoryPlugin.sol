// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlugin.sol";

/**
 * @title InventoryPlugin
 * @dev Example plugin that manages player inventory and items
 */
contract InventoryPlugin is IPlugin {
    string public constant PLUGIN_NAME = "Inventory System";
    uint256 public constant PLUGIN_VERSION = 1;
    
    // Item structure
    struct Item {
        string name;
        string description;
        uint8 rarity; // 1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary
        uint256 value;
        bool isStackable;
    }
    
    // Predefined items
    mapping(uint256 => Item) public items;
    uint256 public totalItems;
    
    event ItemReceived(address indexed player, uint256 indexed itemId, uint256 quantity);
    event ItemUsed(address indexed player, uint256 indexed itemId, uint256 quantity);
    
    constructor() {
        // Initialize some items
        items[1] = Item("Health Potion", "Restores 50 HP", 1, 10, true);
        items[2] = Item("Magic Sword", "A powerful enchanted blade", 3, 500, false);
        items[3] = Item("Gold Coin", "Standard currency", 1, 1, true);
        items[4] = Item("Dragon Scale", "Rare crafting material", 4, 1000, true);
        totalItems = 4;
    }
    
    function getPluginName() external pure override returns (string memory) {
        return PLUGIN_NAME;
    }
    
    function getPluginVersion() external pure override returns (uint256) {
        return PLUGIN_VERSION;
    }
    
    function getRequiredStorageSlots() external pure override returns (uint256) {
        return 20; // More storage needed for inventory
    }
    
    function isCompatible(uint256 coreVersion) external pure override returns (bool) {
        return coreVersion >= 1;
    }
    
    function initialize(address player) external override {
        // Give starting items
        _addItem(player, 1, 3); // 3 Health Potions
        _addItem(player, 3, 100); // 100 Gold Coins
        _setPlayerUint(player, "inventory_slots", 20); // 20 inventory slots
    }
    
    function execute(bytes calldata data) external override returns (bytes memory) {
        bytes4 selector = bytes4(data[:4]);
        
        if (selector == this.addItem.selector) {
            (address player, uint256 itemId, uint256 quantity) = abi.decode(data[4:], (address, uint256, uint256));
            _addItem(player, itemId, quantity);
            return abi.encode(true);
        }
        
        if (selector == this.useItem.selector) {
            (address player, uint256 itemId, uint256 quantity) = abi.decode(data[4:], (address, uint256, uint256));
            _useItem(player, itemId, quantity);
            return abi.encode(true);
        }
        
        if (selector == this.getInventory.selector) {
            (address player) = abi.decode(data[4:], (address));
            return abi.encode(_getPlayerInventory(player));
        }
        
        revert("InventoryPlugin: unknown function selector");
    }
    
    // Plugin functions
    function addItem(address player, uint256 itemId, uint256 quantity) external {
        _addItem(player, itemId, quantity);
    }
    
    function useItem(address player, uint256 itemId, uint256 quantity) external {
        _useItem(player, itemId, quantity);
    }
    
    function getInventory(address player) external view returns (
        uint256[] memory itemIds,
        uint256[] memory quantities
    ) {
        return _getPlayerInventory(player);
    }
    
    // Internal functions
    function _addItem(address player, uint256 itemId, uint256 quantity) internal {
        require(itemId > 0 && itemId <= totalItems, "Invalid item ID");
        require(quantity > 0, "Quantity must be positive");
        
        string memory itemKey = string(abi.encodePacked("item_", _toString(itemId)));
        uint256 currentQuantity = _getPlayerUint(player, itemKey);
        _setPlayerUint(player, itemKey, currentQuantity + quantity);
        
        emit ItemReceived(player, itemId, quantity);
    }
    
    function _useItem(address player, uint256 itemId, uint256 quantity) internal {
        require(itemId > 0 && itemId <= totalItems, "Invalid item ID");
        require(quantity > 0, "Quantity must be positive");
        
        string memory itemKey = string(abi.encodePacked("item_", _toString(itemId)));
        uint256 currentQuantity = _getPlayerUint(player, itemKey);
        require(currentQuantity >= quantity, "Insufficient item quantity");
        
        _setPlayerUint(player, itemKey, currentQuantity - quantity);
        
        emit ItemUsed(player, itemId, quantity);
    }
    
    function _getPlayerInventory(address player) internal view returns (
        uint256[] memory itemIds,
        uint256[] memory quantities
    ) {
        // Check all items for this player
        uint256[] memory tempIds = new uint256[](totalItems);
        uint256[] memory tempQuantities = new uint256[](totalItems);
        uint256 itemCount = 0;
        
        for (uint256 i = 1; i <= totalItems; i++) {
            string memory itemKey = string(abi.encodePacked("item_", _toString(i)));
            uint256 quantity = _getPlayerUint(player, itemKey);
            if (quantity > 0) {
                tempIds[itemCount] = i;
                tempQuantities[itemCount] = quantity;
                itemCount++;
            }
        }
        
        itemIds = new uint256[](itemCount);
        quantities = new uint256[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            itemIds[i] = tempIds[i];
            quantities[i] = tempQuantities[i];
        }
    }
    
    // Storage helpers (same as in AchievementPlugin)
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
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
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
