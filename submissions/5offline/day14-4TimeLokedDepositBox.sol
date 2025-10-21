//SPDX-License-Identifier:MIT

pragma solidity^0.8.0;
//这个不是abstract contract，可以直接deploy

import "./BaseDepositBox.sol";
//先导入

contract TimeLockedDepositBox is BaseDepositBox {
    

    uint256 private unlockTime;
    //比之前的要再多一点功能，时间限制设置
    //用getter来公开

    constructor(uint256 lockDuration) {
        //deploy后来设置这个时间 以秒为单位
        unlockTime = block.timestamp + lockDuration;
    }

    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still time-locked");
        _;
        //modifier也可以用这样的条件
    }

    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
        //报告盒子类型
    }

    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
        return super.getSecret();
        //得到密匙，要看一下 timeUnlocked
    }

    function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }
    //getter函数

    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }
    //看一下剩多少时间
}
