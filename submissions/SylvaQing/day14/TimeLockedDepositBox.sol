// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// 暂时无法打开的金库
import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 private unlockTime;
    
    constructor(uint256 lockDuration){
        unlockTime=block.timestamp+lockDuration;
    }

    // 检查当前时间是否已超过解锁时间
    modifier timeUnlocked(){
        require(block.timestamp>=unlockTime,"Box is still time-locked");
        _;
    }

    //重写内容
    function getBoxType()external pure override returns (string memory) {
        return "TimeLocked";
    }
    function getSecret()public view override onlyOwner timeUnlocked returns (string memory){
        return super.getSecret();
    }
  
    //新增内容
    function getUnlockTime()external view returns (uint256){
        return unlockTime;
    }
        //倒计时助手 
    function getRemainingLockTime()external view returns (uint256){
        if(block.timestamp>=unlockTime) return 0;
        return unlockTime-block.timestamp;
    }
    

}