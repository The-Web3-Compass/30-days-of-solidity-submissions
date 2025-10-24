//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 private unlockTime;     
    //定义一个私有变量 unlockTime，类型为 uint256（无符号整数）,它记录了盒子可以被解锁的区块时间戳

    //定义构造函数，在合约部署时执行一次,部署时确定锁定期限
    constructor(uint256 lockDuration) {     //lockDuration：锁定时长（单位：秒）
        unlockTime = block.timestamp + lockDuration;     //设置未来的“解锁时间”
    }

    //定义了一个自定义修饰符 timeUnlocked(),用于保护某些函数（例如查看秘密），在锁定期内禁止调用
    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still time-locked");     //检查当前区块时间是否已经到达解锁时间,否则报错
        _;
    }

    //实现接口函数 getBoxType()，标识该合约的类型为 "Timelocked"（时间锁类型）
    function getBoxType() external pure override returns (string memory) {
        return "Timelocked";
    }

    //在基础合约的查看秘密功能上，增加了时间锁机制，有当时间到了（block.timestamp >= unlockTime），并且调用者是拥有者，才能查看秘密
    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
        return super.getSecret();
    } 

    //返回该盒子的解锁时间戳
    function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }

    //返回剩余锁定时间（秒），方便用户查看“还要等多久才能查看秘密”
    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }
}