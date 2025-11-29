// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-BaseDepositBox.sol";//导入BaseDepositBox

contract TimeLockedDepositBox is BaseDepositBox {//从BaseDepositBox继承
    uint256 private unlockTime;
    constructor(address initialOwner, uint256 lockDuration,address initialManager)
    BaseDepositBox(initialOwner,initialManager){

        unlockTime = block.timestamp + lockDuration;//解锁时间等于当前时间加上锁住时间
    }

    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still time-locked");//强制必须box解锁
        _;
    }

    function getBoxType() external pure override returns (string memory) {//获得box类型
        return "TimeLocked";
    }

    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
        return super.getSecret();//返回父合约的getSecret
    }

    function getUnlockTime() external view returns (uint256) {
        return unlockTime;//返回解锁时间
    }

    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;//返回剩余解锁时间
    }
}
