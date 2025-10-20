// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GoldVault {
    mapping(address => uint256) public goldBalance;

    // --- Reentrancy Guard Setup ---
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Custom nonReentrant modifier. It locks the function during execution
     * to prevent re-entrant (recursive) calls.
     */
    modifier nonReentrant() {
        // Check if the function is already being executed.
        require(_status != _ENTERED, "Reentrant call blocked");
        
        // Lock the function.
        _status = _ENTERED;

        // Execute the function body.
        _;

        // Unlock the function once execution is complete.
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Allows users to deposit ETH into the vault.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be more than 0");
        goldBalance[msg.sender] += msg.value;
    }

    /**
     * @dev VULNERABLE withdraw function.
     * WARNING: This function is susceptible to reentrancy attacks.
     * It sends ETH (Interaction) *before* updating the user's balance (Effect).
     */
    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // Interaction first: External call to send ETH.
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");

        // Effect last: State update happens after the external call.
        goldBalance[msg.sender] = 0;
    }

    /**
     * @dev SECURE withdraw function.
     * It uses the nonReentrant modifier and follows the
     * Checks-Effects-Interactions pattern.
     */
    function safeWithdraw() external nonReentrant {
        // Check
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // Effect first: Update state *before* the external call.
        goldBalance[msg.sender] = 0;
        
        // Interaction last: External call to send ETH.
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}
