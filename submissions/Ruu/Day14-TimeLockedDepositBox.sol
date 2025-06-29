//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox{

    uint256 private UnlockTime;
    constructor(uint256 LockDuration){
        UnlockTime = block.timestamp + LockDuration;

    }

    modifier TimeUnlocked(){
        require(block.timestamp >= UnlockTime, "Box is still locked");
        _;

    }

    function GetBoxType() external pure override returns(string memory){
        return "TimeLocked";

    }

    function GetSecret() public view override OnlyOwner TimeUnlocked returns(string memory){
        return super.GetSecret();

    }

    function GetUnlockTime() external view returns(uint256){
        return UnlockTime;

    }

    function GetRemainingLockTime() external view returns(uint256){
        if(block.timestamp >= UnlockTime) return 0;
        return UnlockTime - block.timestamp;

    }
    
}
