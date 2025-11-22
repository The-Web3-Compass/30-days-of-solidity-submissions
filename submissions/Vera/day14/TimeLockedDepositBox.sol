// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox{
    uint256 private unlockTime;

    constructor(address _owner,uint256 lockDuration) BaseDepositBox(_owner) {
        unlockTime = block.timestamp + lockDuration;
    }

    modifier timeUnlocked(){
        require(block.timestamp>unlockTime,"Box is still time-locked");
        _;
    }

    function getBoxType() external pure override returns (string memory){
        return "TimeLocked";
    }

    function getSecret() public view override timeUnlocked returns (string memory){
        return super.getSecret();
    }

    function getUnlockTime()external view returns(uint256){
        return unlockTime;
    }

    function getRemainingLockTime()external view returns(uint256){
        if(block.timestamp - unlockTime >=0){
            return block.timestamp - unlockTime;
        }else return 0;
    }

}