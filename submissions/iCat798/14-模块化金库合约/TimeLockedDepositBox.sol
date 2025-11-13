//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./BaseDepositBox.sol";

// 锁定型金库
contract TimeLockedDepositBox is BaseDepositBox{

    // 锁定计时器：存储秘密可访问的时间戳
    uint256 private unlockTime;

    // 构造函数：传入参数lockDuration 锁定时间(s)
    constructor(uint256 lockDuration){
        unlockTime = block.timestamp + lockDuration;
    }

    // 访问守门员：检查当前时间是否已超过解锁时间
    modifier timeUnlocked(){
        require(block.timestamp >= unlockTime, "Box is still locked");
        _;
    }

    // 识别金库类型
    function getBoxType() external pure override returns (string memory) {
    return "TimeLocked";
    }

    // 获取秘密（在超过解锁时间之后）
    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
    return super.getSecret(); // 从基础合约中检索实际的秘密
    }

    // 获取解锁时间戳
    function getUnlockTime() external view returns(uint256){
        return unlockTime;
    }

    // 获取解锁倒计时
    function getRemainingLockTime() external view returns(uint256){
        if(block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }



}