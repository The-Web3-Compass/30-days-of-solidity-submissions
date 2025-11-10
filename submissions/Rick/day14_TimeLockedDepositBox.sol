// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./day14_BaseDepositBox.sol";

// 定时box
contract TimeLockedDepositBox is BaseDepositBox {
    // box 开锁时间
    uint private unLockTime;

    constructor (uint lockTime) {
        unLockTime = block.timestamp + lockTime;
    }

    function getBoxType() external pure returns (string memory){
        return unicode"限时锁定box";
    }

    function getUnLockTime() view  external checkBoxOwner returns(uint) {
        return unLockTime;
    }

    function getRemainingLockTime() view external returns(uint) {
        if (block.timestamp >= unLockTime) return 0;
        return unLockTime - block.timestamp;
    }
    
    function getSecret()public view override  returns (string memory) {
        require(block.timestamp > unLockTime , unicode"box in lock");
        return super.getSecret();
    }


}