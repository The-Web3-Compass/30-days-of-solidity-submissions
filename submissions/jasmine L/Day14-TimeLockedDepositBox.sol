// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox{
    uint256 private unlockTime;//没有人可以直接访问

    constructor(uint256 _unlockTime){
        unlockTime = _unlockTime + block.timestamp;
    }
    
    modifier timeLocked(){
        require(block.timestamp >= unlockTime, "Locked time");
        _;
    }

    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }

    function getUnlockTime() public view returns(uint256){
        return unlockTime;
    }

    function getSecret() public view override  onlyOwner timeLocked returns(string memory){
        return super.getSecret();
    }

    function getRemainLockTime() external view returns (uint256){
        //是否结束了
        require(block.timestamp <= unlockTime, "Unlock");
        return unlockTime-block.timestamp;
    }

}