// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title InventoryPlugin
 * @author shivam
 * @notice Manages player inventory items via delegatecall from PlayerProfile.
 * @dev Plugin contract for inventory logic. Modifies CALLER (PlayerProfile) storage.
 * Ensure storage slots are allocated in PlayerProfile and avoid collisions with other plugins or core state.
 */
contract InventoryPlugin {
    /// @notice Mapping storing item balances for players (playerAddress => itemId => quantity).
    /// @dev Resides in the PlayerProfile contract's storage when called via delegatecall.
    mapping(address => mapping(uint256 => uint256)) public inventoryItems;

    /// @notice Emitted when items are added to a player's inventory.
    /// @param player Address of the player whose inventory was updated.
    /// @param itemId ID of the item added.
    /// @param quantity Amount of the item added.
    /// @param newBalance Player's new balance of that item.
    /// @dev `msg.sender` in the delegatecall context is the original player calling PlayerProfile.
    event ItemAdded(address indexed player, uint256 indexed itemId, uint256 quantity, uint256 newBalance);

    /// @notice Emitted when items are removed from a player's inventory.
    /// @param player Address of the player whose inventory was updated.
    /// @param itemId ID of the item removed.
    /// @param quantity Amount of the item removed.
    /// @param newBalance Player's new balance of that item.
    /// @dev `msg.sender` in the delegatecall context is the original player calling PlayerProfile.
    event ItemRemoved(address indexed player, uint256 indexed itemId, uint256 quantity, uint256 newBalance);

    /// @notice Error thrown when attempting to remove more items than the player possesses.
    /// @param player The player address.
    /// @param itemId The item ID.
    /// @param requested The amount requested to remove.
    /// @param available The amount actually available.
    error InsufficientBalance(address player, uint256 itemId, uint256 requested, uint256 available);

    /**
     * @notice Adds a specified quantity of an item to the caller's inventory (msg.sender of PlayerProfile call).
     * @param _itemId The ID of the item to add.
     * @param _quantity The amount of the item to add. Must be greater than 0.
     * @dev Called via delegatecall from PlayerProfile. Modifies 'inventoryItems' mapping
     * in PlayerProfile's storage. Emits {ItemAdded} event. Requires _quantity > 0.
     */
    function addItem(uint256 _itemId, uint256 _quantity) external {
        require(_quantity > 0, "Quantity must be positive");
        address player = msg.sender; // Original caller of PlayerProfile
        uint256 currentBalance = inventoryItems[player][_itemId];
        uint256 newBalance = currentBalance + _quantity;
        inventoryItems[player][_itemId] = newBalance;
        emit ItemAdded(player, _itemId, _quantity, newBalance);
    }

    /**
     * @notice Removes a specified quantity of an item from the caller's inventory (msg.sender of PlayerProfile call).
     * @param _itemId The ID of the item to remove.
     * @param _quantity The amount of the item to remove. Must be greater than 0.
     * @dev Called via delegatecall from PlayerProfile. Modifies 'inventoryItems' mapping
     * in PlayerProfile's storage. Emits {ItemRemoved} event. Requires _quantity > 0.
     * @custom:error InsufficientBalance when _quantity exceeds player's balance for _itemId.
     */
    function removeItem(uint256 _itemId, uint256 _quantity) external {
        require(_quantity > 0, "Quantity must be positive");
        address player = msg.sender; // Original caller of PlayerProfile
        uint256 currentBalance = inventoryItems[player][_itemId];

        if (currentBalance < _quantity) {
            revert InsufficientBalance(player, _itemId, _quantity, currentBalance);
        }

        uint256 newBalance = currentBalance - _quantity;
        inventoryItems[player][_itemId] = newBalance;
        emit ItemRemoved(player, _itemId, _quantity, newBalance);
    }

    /**
     * @notice Gets the balance of a specific item for a given player.
     * @param _player The address of the player whose balance to check.
     * @param _itemId The ID of the item to check.
     * @return uint256 The quantity of the item the player holds.
     * @dev Reads from the 'inventoryItems' mapping in the PlayerProfile contract's storage context.
     */
    function getItemBalance(address _player, uint256 _itemId) external view returns (uint256) {
        return inventoryItems[_player][_itemId];
    }
}