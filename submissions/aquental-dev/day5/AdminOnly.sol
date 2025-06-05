// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract AdminOnly {
    address public owner;
    mapping(address => bool) public canWithdrawWithoutApproval;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    uint256 public totalTreasure;

    event TreasureAdded(address indexed owner, uint256 amount);
    event TreasureWithdrawn(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event WithdrawalApproved(address indexed user, uint256 amount);
    event WithdrawalPermissionUpdated(address indexed user, bool canWithdrawWithoutApproval);
    event WithdrawalStatusesReset();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier canWithdraw(address user, uint256 amount) {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(amount <= totalTreasure, "Insufficient treasure in chest");
        require(!hasWithdrawn[user], "User has already withdrawn");
        require(
            canWithdrawWithoutApproval[user] || withdrawalAllowance[user] >= amount,
            "User not authorized or insufficient allowance"
        );
        _;
    }

    // Constructor sets the deployer as the initial owner
    constructor() {
        owner = msg.sender;
    }

    // Allows the owner to add treasure (ETH) to the contract
    // @dev Updates totalTreasure and emits TreasureAdded event
    // @notice Only the owner can call this function; requires non-zero ETH to be sent
    function addTreasure() external payable onlyOwner {
        require(msg.value > 0, "Must send treasure to add");
        totalTreasure += msg.value;
        emit TreasureAdded(msg.sender, msg.value);
    }

    // Allows the owner to withdraw treasure to a specified address
    // @dev Reduces totalTreasure and sends ETH to the recipient
    // @param recipient The address to receive the withdrawn treasure
    // @param amount The amount of ETH to withdraw
    // @notice Only the owner can call; ensures sufficient treasure is available
    function withdrawTreasure(address payable recipient, uint256 amount) 
        external 
        onlyOwner 
    {
        require(amount <= totalTreasure, "Insufficient treasure");
        totalTreasure -= amount;
        recipient.transfer(amount);
        emit TreasureWithdrawn(recipient, amount);
    }

    // Transfers ownership of the contract to a new address
    // @dev Updates the owner and emits OwnershipTransferred event
    // @param newOwner The address to become the new owner
    // @notice Only the current owner can call; prevents zero address or same owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner must be different");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Sets whether a user can withdraw without specific approval
    // @dev Updates canWithdrawWithoutApproval mapping and emits WithdrawalPermissionUpdated event
    // @param user The address to set permission for
    // @param status True if user can withdraw without approval, false otherwise
    // @notice Only the owner can call; prevents zero address
    function setWithdrawalPermission(address user, bool status) external onlyOwner {
        require(user != address(0), "Invalid user address");
        canWithdrawWithoutApproval[user] = status;
        emit WithdrawalPermissionUpdated(user, status);
    }

    // Approves a specific withdrawal amount for a user
    // @dev Updates withdrawalAllowance mapping and emits WithdrawalApproved event
    // @param user The address to approve withdrawal for
    // @param amount The amount of ETH the user is allowed to withdraw
    // @notice Only the owner can call; prevents zero address or zero amount
    function approveWithdrawal(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Approval amount must be greater than 0");
        withdrawalAllowance[user] = amount;
        emit WithdrawalApproved(user, amount);
    }

    // Allows a user to withdraw treasure if authorized
    // @dev Checks permissions, updates mappings, reduces totalTreasure, and sends ETH
    // @param amount The amount of ETH to withdraw
    // @notice User must have permission or sufficient allowance; prevents repeat withdrawals
    function userWithdraw(uint256 amount) 
        external 
        canWithdraw(msg.sender, amount) 
    {
        hasWithdrawn[msg.sender] = true;
        if (!canWithdrawWithoutApproval[msg.sender]) {
            withdrawalAllowance[msg.sender] = 0;
        }
        totalTreasure -= amount;
        payable(msg.sender).transfer(amount);
        emit TreasureWithdrawn(msg.sender, amount);
    }

    // Resets withdrawal statuses for future implementation
    // @dev Emits WithdrawalStatusesReset event; can be extended to reset mappings
    // @notice Only the owner can call; currently emits event for tracking
    function resetWithdrawalStatuses() external onlyOwner {
        emit WithdrawalStatusesReset();
        // Note: To reset specific addresses, additional logic would be needed
        // as Solidity mappings cannot be iterated or reset entirely
    }
}
