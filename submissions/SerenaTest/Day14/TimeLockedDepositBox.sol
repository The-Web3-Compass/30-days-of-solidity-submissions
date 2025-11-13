//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox{

    uint256 private unlockTime;
    constructor(uint256 lockDuration){
        unlockTime = block.timestamp + lockDuration;
    }

    //使用访问修饰符设置锁定  只有超过锁定时间用户才能访问
    modifier timeUnlocked(){
        require(block.timestamp >= unlockTime, "Box is still locked");
        _;
    }

    function getBoxType() external pure override returns (string memory) {
    return "TimeLocked";
}
    function getSecret() public view override onlyOwner timeUnlocked returns (string memory) {
    return super.getSecret();
}

    function getUnlockTime() external view returns(uint256){
        return unlockTime;
    }

    //返回剩余时间
    function getRemainingLockTime() external view returns(uint256){
        if(block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }



}