// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Day14-BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox{

    uint256 private unlockTime;

    constructor(uint256 lockDuration) {
        unlockTime = block.timestamp + lockDuration;
    }

    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still time-locked");
        _;
    }


    function getBoxType()external pure override returns (string memory){
        return "TimeLocked";

    }

    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
        // We can't return secret derectly.
        return super.getSecret();
    }


     function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }

    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }


}