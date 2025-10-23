// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox{
    uint256 private unlockTime;

    constructor(uint256 lockDuration){
        unlockTime = depositTime + lockDuration;
    }

    modifier timeUnlocked(){
        require(block.timestamp >= unlockTime,"Still not yet");
        _;
    }

    function getSecret() public view override onlyOwner timeUnlocked returns(string memory){
        return super.getSecret();
    }

    function getBoxType()public pure override returns(string memory){
        return "TimeLocked";
    }

    function getRemainingTime() external view returns(uint256){
        if(block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }

}