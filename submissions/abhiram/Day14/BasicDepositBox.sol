//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./BaseDepositBox.sol";

/**
 * @title BasicDepositBox
 * @notice A basic deposit box with standard functionality
 * @dev Extends BaseDepositBox without additional restrictions
 */
contract BasicDepositBox is BaseDepositBox {
    /**
     * @notice Create a new basic deposit box
     * @param initialOwner Address of the initial owner
     */
    constructor(address initialOwner) BaseDepositBox(initialOwner) {}
    
    /**
     * @inheritdoc IDepositBox
     */
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}
