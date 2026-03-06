// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AdminOnly (Treasure Chest)
 * @author Nadiatus Salam
 * @notice A basic access-controlled treasure chest using modifier and msg.sender.
 * @dev Demonstrates: modifiers, ownership, if/else flow, and secure ETH withdrawals.
 */
contract AdminOnly {
    // Owner (admin) of the treasure chest
    address public owner;

    // Per-user allowance in wei and withdrawal status (one-time per allowance)
    mapping(address => uint256) public allowance;
    mapping(address => bool) public hasWithdrawn;
    // Total unclaimed allowances reserved for users
    uint256 public reservedAllowance;

    // Simple reentrancy guard
    bool private locked;

    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TreasureAdded(address indexed from, uint256 amount);
    event AllowanceSet(address indexed user, uint256 amount);
    event AllowanceCleared(address indexed user);
    event WithdrawalByUser(address indexed user, uint256 amount);
    event WithdrawalByOwner(address indexed owner, uint256 amount);
    event WithdrawalReset(address indexed user);

    // Custom errors (gas-efficient)
    error NotOwner();
    error ZeroAddress();
    error NoValueSent();
    error AlreadyWithdrawn();
    error NoAllowance();
    error InsufficientTreasure();
    error WithdrawFailed();
    error ReentrantCall();
    error DirectEtherNotAllowed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier nonReentrant() {
        if (locked) revert ReentrantCall();
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @notice Owner deposits ETH into the chest.
     */
    function addTreasure() external payable onlyOwner {
        if (msg.value == 0) revert NoValueSent();
        emit TreasureAdded(msg.sender, msg.value);
    }

    /**
     * @notice Owner can set an allowance for a user in wei.
     * @param user The beneficiary.
     * @param amount Amount in wei the user is allowed to withdraw (one-time).
     */
    function setAllowance(address user, uint256 amount) external onlyOwner {
        if (user == address(0)) revert ZeroAddress();
        uint256 old = allowance[user];
        // Remove previous reservation if not withdrawn yet
        if (!hasWithdrawn[user] && old > 0) {
            reservedAllowance -= old;
        }
        allowance[user] = amount;
        hasWithdrawn[user] = false;
        if (amount > 0) {
            reservedAllowance += amount;
        }
        emit AllowanceSet(user, amount);
    }

    /**
     * @notice Owner can clear a user's allowance.
     */
    function clearAllowance(address user) external onlyOwner {
        uint256 old = allowance[user];
        if (!hasWithdrawn[user] && old > 0) {
            reservedAllowance -= old;
        }
        allowance[user] = 0;
        emit AllowanceCleared(user);
    }

    /**
     * @notice User withdraws their allowance once, if approved by the owner.
     * @dev CEI + nonReentrant guard; zeroes state before transferring ETH.
     */
    function withdraw() external nonReentrant {
        if (hasWithdrawn[msg.sender]) revert AlreadyWithdrawn();
        uint256 amt = allowance[msg.sender];
        if (amt == 0) revert NoAllowance();
        if (address(this).balance < amt) revert InsufficientTreasure();

        // Effects
        hasWithdrawn[msg.sender] = true;
        allowance[msg.sender] = 0;
        reservedAllowance -= amt;

        // Interaction
        (bool ok, ) = payable(msg.sender).call{value: amt}("");
        if (!ok) {
            // Restore state on failure
            hasWithdrawn[msg.sender] = false;
            allowance[msg.sender] = amt;
            reservedAllowance += amt;
            revert WithdrawFailed();
        }

        emit WithdrawalByUser(msg.sender, amt);
    }

    /**
     * @notice Owner can withdraw ETH directly from the chest.
     * @param amount Amount in wei.
     */
    function ownerWithdraw(uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert NoValueSent();
        uint256 bal = address(this).balance;
        if (bal < amount) revert InsufficientTreasure();
        // Preserve user funds: post-withdraw balance must cover reserved allowances
        if (bal - amount < reservedAllowance) revert InsufficientTreasure();

        (bool ok, ) = payable(owner).call{value: amount}("");
        if (!ok) revert WithdrawFailed();

        emit WithdrawalByOwner(owner, amount);
    }

    /**
     * @notice Owner resets a user's withdrawal status (e.g., to allow another round).
     * @dev Does not change allowance; can be combined with setAllowance.
     */
    function resetWithdrawal(address user) external onlyOwner {
        hasWithdrawn[user] = false;
        emit WithdrawalReset(user);
    }

    /**
     * @notice Transfer ownership of the treasure chest to a new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }

    /**
     * @notice Prevents accidental deposits from non-owner; owner may deposit via receive.
     */
    receive() external payable {
        if (msg.sender != owner) revert DirectEtherNotAllowed();
        if (msg.value == 0) revert NoValueSent();
        emit TreasureAdded(msg.sender, msg.value);
    }

    fallback() external payable {
        revert DirectEtherNotAllowed();
    }
}