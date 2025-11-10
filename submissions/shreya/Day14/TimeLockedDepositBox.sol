// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public lockTime;

    modifier notLocked() {
        require(block.timestamp >= lockTime, "Deposit box is still locked");
        _;
    }

    constructor(uint256 _lockDuration) {
        lockTime = block.timestamp + _lockDuration;
    }

    function getSecret() public view override onlyOwner notLocked returns (string memory) {
        return super.getSecret();
    }

    function getBoxType() public pure override returns (string memory) {
        return "TimeLocked";
    }
}