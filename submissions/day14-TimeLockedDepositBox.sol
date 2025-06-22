// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "day14-BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 private unlockTime;

    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still time-locked");
        _;
    }


    constructor(uint256 _lockDuration) {
        unlockTime = block.timestamp + _lockDuration;
    }

    function getBoxType() external pure override returns (string memory) {
        return " TimeLockedDeposit";
    }

    function getSecret()  public view override onlyOwner timeUnlocked returns (string memory) {
        return super.getSecret();
    }

    function getUnlockTime() external view returns (uint256) {
        return  unlockTime;
    }

    function getRemainingLockTime() external view returns (uint256) {
        if(block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }
}
