// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../contracts/IPlugin.sol";

/**
 * @title InventoryPlugin
 * @dev Plugin for managing player inventory and items
 * 
 * Allows players to store and manage items in their profile.
 * Demonstrates delegatecall for complex state management.
 */
contract InventoryPlugin is IPlugin {
    // ============ Data Structures ============

    struct Item {
        bytes32 itemId;
        string name;
        uint256 quantity;
        string rarity; // "common", "rare", "epic", "legendary"
    }

    // ============ Events ============

    event ItemAdded(address indexed player, bytes32 itemId, string name, uint256 quantity);
    event ItemRemoved(address indexed player, bytes32 itemId, uint256 quantity);
    event ItemCrafted(address indexed player, string resultItem);

    // ============ Errors ============

    error ItemNotFound(bytes32 itemId);
    error InsufficientItems(bytes32 itemId);
    error InvalidItemData(string reason);

    // ============ Plugin Interface ============

    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "Inventory Plugin";
    }

    // ============ Inventory Functions ============

    /**
     * @dev Adds an item to the player's inventory
     * 
     * When called via delegatecall, this modifies the calling profile's storage.
     * The profile contract is responsible for authorization.
     * 
     * @param _itemId The unique item identifier
     * @param _name The item's display name
     * @param _quantity How many of this item to add
     * @param _rarity The item's rarity level
     */
    function addItem(
        bytes32 _itemId,
        string calldata _name,
        uint256 _quantity,
        string calldata _rarity
    ) external {
        require(_quantity > 0, "Quantity must be greater than 0");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_rarity).length > 0, "Rarity cannot be empty");

        // Validate rarity values
        bytes memory rarityBytes = bytes(_rarity);
        bool validRarity = bytes("common").length == rarityBytes.length ||
                          bytes("rare").length == rarityBytes.length ||
                          bytes("epic").length == rarityBytes.length ||
                          bytes("legendary").length == rarityBytes.length;

        require(validRarity, "Invalid rarity");

        emit ItemAdded(msg.sender, _itemId, _name, _quantity);
    }

    /**
     * @dev Removes items from the player's inventory
     * 
     * @param _itemId The item to remove
     * @param _quantity How many to remove
     */
    function removeItem(bytes32 _itemId, uint256 _quantity) external {
        require(_quantity > 0, "Quantity must be greater than 0");

        emit ItemRemoved(msg.sender, _itemId, _quantity);
    }

    /**
     * @dev Gets item count (would access actual storage in production)
     * 
     * @return The total number of unique items
     */
    function getItemCount() external pure returns (uint256) {
        return 0;
    }

    /**
     * @dev Gets an item by ID (would access actual storage in production)
     * 
     * @param _itemId The item identifier
     * @return name The item name
     * @return quantity The quantity owned
     * @return rarity The item rarity
     */
    function getItem(bytes32 _itemId)
        external
        pure
        returns (string memory name, uint256 quantity, string memory rarity)
    {
        return ("", 0, "");
    }

    /**
     * @dev Crafts a new item from existing items
     * 
     * Demonstrates complex plugin logic that modifies inventory
     * 
     * @param _recipe The crafting recipe name
     */
    function craftItem(string calldata _recipe) external {
        require(bytes(_recipe).length > 0, "Recipe cannot be empty");

        emit ItemCrafted(msg.sender, _recipe);
    }

    /**
     * @dev Gets inventory space used (would access storage in production)
     * 
     * @return used The space currently used
     * @return total The total available space
     */
    function getInventorySpace() external pure returns (uint256 used, uint256 total) {
        return (0, 100);
    }
}
