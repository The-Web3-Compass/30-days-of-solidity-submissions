// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    // State variables
    address public owner;
    uint256 public treasureAmount;
    uint256 public withdrawCooldown = 60;
    uint256 public latestWithdrawTime;

    mapping(address => uint256) public maxWithdrawal;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawn;
    
    // Constructor sets the contract creator as the owner
    constructor() {
        owner = msg.sender;
    }
    
    // Modifier for owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _;
    }

    // Only the owner can add treasure
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;

        // ❌ original: print("Add Treasure");
        // FIX: Solidity has no `print()`. Use an event instead.
        emit LogAction("Add Treasure", msg.sender, amount);
    }
    
    function setMaxWithdrawal(address _user, uint256 _maxAmount) public onlyOwner {
        maxWithdrawal[_user] = _maxAmount;
    }

    // Only the owner can approve withdrawals
    function approveWithdrawal(address _user, uint256 _amount) public onlyOwner {
        require(_amount <= treasureAmount, "Not enough treasure available");
        require(_amount <= maxWithdrawal[_user], "Exceeds user's max withdrawal limit");

        withdrawalAllowance[_user] = _amount;
    }
    
    
    // Anyone can attempt to withdraw, but only those with allowance will succeed
    function withdrawTreasure(uint256 amount) public {
        // ❌ original: require(time.now - latestWithdrawTime > withdrawCooldown, ...)
        // FIX: Solidity does not have `time.now`. Use `block.timestamp`.
        require(block.timestamp - latestWithdrawTime > withdrawCooldown, "Wait for cooldown period");

        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount -= amount;
            latestWithdrawTime = block.timestamp;
            emit LogAction("Owner withdrawal", msg.sender, amount);
            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];
        
        // Check if user has an allowance and hasn't withdrawn yet
        require(allowance > 0, "You don't have any treasure allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn your treasure");
        require(allowance <= treasureAmount, "Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed");
        
        // Mark as withdrawn and reduce treasure
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= amount;
        withdrawalAllowance[msg.sender] = 0;

        // ❌ original: latestWithdrawTime = time.now;
        // FIX: replaced with block.timestamp
        latestWithdrawTime = block.timestamp;

        // ❌ original: print("Treasure Withdraw");
        // FIX: replaced with event emission
        emit LogAction("Treasure Withdraw", msg.sender, amount);

        payable(msg.sender).transfer(amount);
    }
    
    // Only the owner can reset someone's withdrawal status
    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    // Only the owner can transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
        emit LogAction("Ownership Transferred", newOwner, 0);
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

    // ❌ original:
    // function viewUserStatus(address _userAddress) public view returns (string) {
    //     print(f"Approved: {withdrawlAllowance[_userAddress]}");
    //     print(f"Already Withdraw: {hasWithdrawn[_userAddress]}");
    // }
    // PROBLEMS:
    // 1. Solidity cannot print.
    // 2. f"..." string interpolation invalid.
    // 3. wrong variable name: withdrawlAllowance.
    // 4. wrong return type for multiple values.
    // FIX: return structured data instead.
    function viewUserStatus(address _userAddress) public view returns (uint256 allowance, bool withdrawn) {
        allowance = withdrawalAllowance[_userAddress];
        withdrawn = hasWithdrawn[_userAddress];
    }

    // Added event for logging actions instead of print
    event LogAction(string action, address indexed user, uint256 amount);
}
