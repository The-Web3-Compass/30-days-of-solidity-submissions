//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./SafeDepositBox.sol";
import "./IDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

/**
 * @title ExampleUsage
 * @notice Example contract demonstrating how to use the Smart Bank system
 * @dev This contract shows common usage patterns and scenarios
 */
contract ExampleUsage {
    SafeDepositBox public manager;
    
    constructor() {
        // Deploy the safe deposit box manager
        manager = new SafeDepositBox();
    }
    
    /**
     * @notice Example 1: Create and use a basic deposit box
     */
    function example1_BasicBox() external {
        // Create a basic box
        address boxAddress = manager.createBasicBox();
        IDepositBox box = IDepositBox(boxAddress);
        
        // Store a secret
        box.storeSecret("My secret message");
        
        // Deposit funds
        box.deposit{value: 1 ether}();
        
        // Check balance
        uint256 balance = box.getBalance();
        require(balance == 1 ether, "Balance mismatch");
        
        // Retrieve secret
        string memory secret = box.retrieveSecret();
        require(
            keccak256(bytes(secret)) == keccak256(bytes("My secret message")),
            "Secret mismatch"
        );
        
        // Withdraw funds
        box.withdraw(0.5 ether);
    }
    
    /**
     * @notice Example 2: Premium box with limits
     */
    function example2_PremiumBox() external {
        // Create a premium box
        address boxAddress = manager.createPremiumBox();
        PremiumDepositBox box = PremiumDepositBox(boxAddress);
        
        // Deposit enough to meet minimum balance
        box.deposit{value: 2 ether}();
        
        // Check remaining daily withdrawal
        uint256 remaining = box.getRemainingDailyWithdrawal();
        require(remaining == 1 ether, "Daily limit mismatch");
        
        // Withdraw respecting daily limit
        box.withdraw(0.5 ether);
        
        // Check updated remaining limit
        remaining = box.getRemainingDailyWithdrawal();
        require(remaining == 0.5 ether, "Remaining limit mismatch");
        
        // Balance should be 1.5 ETH and above minimum
        require(box.getBalance() == 1.5 ether, "Balance incorrect");
    }
    
    /**
     * @notice Example 3: Time-locked box
     */
    function example3_TimeLockedBox() external {
        // Create a box locked for 1 hour
        address boxAddress = manager.createTimeLockedBox(1 hours);
        TimeLockedDepositBox box = TimeLockedDepositBox(boxAddress);
        
        // Deposit funds
        box.deposit{value: 5 ether}();
        
        // Check remaining lock time
        uint256 remainingTime = box.getRemainingLockTime();
        require(remainingTime > 0, "Should be locked");
        
        // Extend lock by another hour
        box.extendLock(1 hours);
        
        // Note: In real usage, would need to wait for lock to expire
        // before being able to withdraw
    }
    
    /**
     * @notice Example 4: Ownership transfer
     */
    function example4_OwnershipTransfer(address newOwner) external {
        // Create a box
        address boxAddress = manager.createBasicBox();
        IDepositBox box = IDepositBox(boxAddress);
        
        // Deposit and store secret
        box.deposit{value: 1 ether}();
        box.storeSecret("Transferring ownership");
        
        // Verify current owner
        require(box.getOwner() == address(this), "Wrong owner");
        
        // Transfer ownership through manager (updates tracking)
        manager.transferBoxOwnership(boxAddress, newOwner);
        
        // Verify new owner
        require(box.getOwner() == newOwner, "Transfer failed");
        
        // Original owner can no longer access
        // box.retrieveSecret(); // This would fail
    }
    
    /**
     * @notice Example 5: Manager interactions
     */
    function example5_ManagerInteractions() external view {
        // Get all boxes for this contract
        address[] memory myBoxes = manager.getUserBoxes(address(this));
        
        // Iterate through boxes and get info
        for (uint i = 0; i < myBoxes.length; i++) {
            (address owner, , ) = 
                manager.getBoxInfo(myBoxes[i]);
                
            // Check that we own all boxes
            require(owner == address(this), "Ownership mismatch");
        }
        
        // Get total boxes in system
        uint256 totalBoxes = manager.getTotalBoxes();
        require(totalBoxes >= myBoxes.length, "Total boxes mismatch");
    }
    
    /**
     * @notice Example 6: Using manager to interact with boxes
     */
    function example6_ManagerProxy() external {
        // Create a box
        address boxAddress = manager.createBasicBox();
        
        // Store secret through manager
        manager.storeSecretInBox(boxAddress, "Via manager");
        
        // Retrieve secret through manager
        string memory secret = manager.retrieveSecretFromBox(boxAddress);
        require(
            keccak256(bytes(secret)) == keccak256(bytes("Via manager")),
            "Secret mismatch"
        );
        
        // Deposit through manager
        manager.depositToBox{value: 1 ether}(boxAddress);
        
        // Verify deposit
        (,uint256 balance,) = manager.getBoxInfo(boxAddress);
        require(balance == 1 ether, "Deposit failed");
    }
    
    /**
     * @notice Example 7: Multiple box types
     */
    function example7_MultipleBoxTypes() external view {
        // Get all boxes
        address[] memory myBoxes = manager.getUserBoxes(address(this));
        
        // Count box types
        uint256 basicCount = 0;
        uint256 premiumCount = 0;
        uint256 timeLockedCount = 0;
        
        for (uint i = 0; i < myBoxes.length; i++) {
            (,, string memory boxType) = manager.getBoxInfo(myBoxes[i]);
            
            if (keccak256(bytes(boxType)) == keccak256(bytes("Basic"))) {
                basicCount++;
            } else if (keccak256(bytes(boxType)) == keccak256(bytes("Premium"))) {
                premiumCount++;
            } else if (keccak256(bytes(boxType)) == keccak256(bytes("TimeLocked"))) {
                timeLockedCount++;
            }
        }
        
        // User can have multiple boxes of different types
    }
    
    // Allow contract to receive ETH
    receive() external payable {}
}
