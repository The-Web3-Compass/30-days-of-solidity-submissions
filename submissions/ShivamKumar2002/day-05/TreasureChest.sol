// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AdminOnly
 * @author shivam
 * @notice A simple contract to simulate a treasure chest with access control.
 *   How it works:
     - Only the owner can add treasure.
     - Only the owner or the users approved by owner can withdraw treasure.
     - Approved users can withdraw treasure only once per allowance.
     - Owner can also transfer ownership of the treasure chest.
 */
contract AdminOnly {
    /// @notice Error thrown when an action is not allowed by user.
    /// @param user Address of user.
    error NotAllowed(address user);

    /// @notice Error thrown when available quantity of treasure item is insufficient for withdrawal.
    /// @param item Treasure item for which withdrawal was requested.
    /// @param requested Quantity of item requested.
    /// @param available Quantity of item currently available in chest.
    error InsufficientQuantity(string item, uint256 requested, uint256 available);

    /// @notice Event emitted when the owner of treasure chest changes.
    /// @param oldOwner Address of old owner of treasure.
    /// @param newOwner Address of new owner of treasure.
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Event emitted when any treasure item is deposited.
    /// @param item Treasure item.
    /// @param quantity Quantity of treasure item.
    event TreasureDeposited(string indexed item, uint256 indexed quantity);

    /// @notice Event emitted when any treasure item is withdrawn.
    /// @param user User who has withdrawn the item.
    /// @param item Treasure item.
    /// @param quantity Quantity of treasure item.
    event TreasureWithdrawn(address indexed user, string indexed item, uint256 indexed quantity);

    /// @notice Owner of the treasure chest
    address public owner;

    /// @notice Mapping of treasure item to quantity
    mapping(string => uint256) public treasures;

    /// @notice Mapping of user address to boolean indicating whether he is approved for withdrawing treasure
    mapping(address => bool) private approvals;

    /// @notice Initializes the contract by setting initial owner to contract creator
    constructor() {
        owner = msg.sender;
    }

    /// @notice Modifier that restricts access to only the contract owner.
    /// @custom:error NotAllowed if caller is not owner.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotAllowed(msg.sender);
        }
        _;
    }

    /// @notice Modifier that restricts access to the owner or approved users.
    /// @custom:error NotAllowed if caller is not owner and not approved
    modifier onlyApproved() {
        if (msg.sender != owner && !approvals[msg.sender]) {
            revert NotAllowed(msg.sender);
        }
        _;
    }

    /// @notice Set new owner of contract.
    /// @param newOwner Address of new owner.
    /// @dev Only the owner of contract can use this function.
    function setOwner(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnerChanged(oldOwner, newOwner);
    }

    /// @notice Approve given address for withdrawing treasure item once.
    /// @param user Address of user to approve.
    /// @dev Only the owner can use this function.
    function approveWithdrawal(address user) external onlyOwner {
        approvals[user] = true;
    }

    /// @notice Revoke approval of given address for withdrawing treasure item.
    /// @param user Address of user to revoke approval.
    /// @dev Only the owner can use this function.
    function revokeApproval(address user) external onlyOwner {
        approvals[user] = false;
    }

    /// @notice Deposit given treasure item to chest.
    /// @param item Treasure item.
    /// @param quantity Quantity of item to deposit.
    /// @dev Only the owner can use this function.
    function depositTreasure(string calldata item, uint256 quantity) external onlyOwner {
        require(quantity > 0, "Quantity must be greater than 0");
        treasures[item] += quantity;
        emit TreasureDeposited(item, quantity);
    }

    /// @notice Withdraw treasure item from chest.
    /// @param item Treasure item.
    /// @param quantity Quantity of item to withdraw.
    /// @dev Only the owner or approved users can use this function.
    /// @custom:error InsufficientQuantity if requested withdrawal quantity is less than available quantity of item.
    function withdrawTreasure(string calldata item, uint256 quantity) external onlyApproved {
        require(quantity > 0, "Quantity must be greater than 0");
        uint256 available = treasures[item];
        if (quantity > available) {
            revert InsufficientQuantity(item, quantity, available);
        }
        // revoke approval
        approvals[msg.sender] = false;
        // reduce quantity
        treasures[item] -= quantity;
        emit TreasureWithdrawn(msg.sender, item, quantity);
    }
}