// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {

    uint256 private unlockTime;

    constructor(address _owner, uint256 lockDuration) {
        owner = _owner;
        depositTime = block.timestamp;
        unlockTime = block.timestamp + lockDuration;
    }

    modifier TimeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still locked");
        _;
    }

    function getBoxType() external pure override returns (string memory) {
        return  "Timelocked";
    }

    function getSecret() public view override TimeUnlocked returns (string memory) {
        return super.getSecret();
    }

    function getUnlockTime() external view returns(uint256) {
        return unlockTime;
    }

    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }

}