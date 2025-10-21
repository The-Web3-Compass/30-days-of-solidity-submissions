// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AdminOnly {
    address public owner;

    uint256 public treasureAmount;

    // Tracking how much each address is allowed to withdraw.
    mapping(address => uint256) public withdrawalAllowance;

    // Tracking which address has already been withdrawn
    mapping(address => bool) public hasWithdrawn;

    // Add a cooldown timer: users can only withdraw once every X minutes
    mapping(address => uint256) public lastWithdrawalTime;
    uint256 public constant COOLDOWN_PERIOD = 5 minutes;

    // Add a maximum withdrawal limit per user
    // 1 ETH = 10^18 wei
    uint256 public constant MAXIMUN_WITHDRAWAL = 1 * 10 ** 18;

    constructor() {
        owner = msg.sender;
    }

    // It’s cleaner, safer, and easier to manage than "require"
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Access denied: Only the owner can perform this action"
        );
        // The _ is where the rest of the function will be inserted if the check passes.
        _;
    }

    function addThreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;
    }

    function approveWithdrawal(
        address recipient,
        uint256 amount
    ) public onlyOwner {
        require(amount < treasureAmount, "You don't have enough money");
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            require(amount <= treasureAmount, "You don't have enough money");
            treasureAmount -= amount;
            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You has already been withdrawn");
        require(
            allowance <= treasureAmount,
            "Not enough treasure in the chest"
        );

        // Add a cooldown timer: users can only withdraw once every X minutes
        require(
            block.timestamp >= lastWithdrawalTime[msg.sender] + COOLDOWN_PERIOD,
            "Try later"
        );
        
        // Add a maximum withdrawal limit per user
        require(
            allowance <= MAXIMUN_WITHDRAWAL,
            "The maximum limit for this time has been withdrawn"
        );

        hasWithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;

        lastWithdrawalTime[msg.sender] = block.timestamp;
    }

    function resetWithdrawal(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    // Telling users if they’re approved and whether they’ve already withdrawn
    function check(address user) public view returns (bool, bool) {
        bool approvedBool = false;
        bool withdrawnBool = false;
        if (withdrawalAllowance[user] > 0) {
            approvedBool = true;
            withdrawnBool = hasWithdrawn[user];
        }

        return (approvedBool, withdrawnBool);
    }
}
