//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

import "./Day14BaseDepositBox.sol";
// This contract adds some new features: users can store a secret, but users cannoy retrieve it until a specific time has passed.
contract TimeLockedDepositBox is BaseDepositBox{
    uint256 private unlockTime;

    constructor(uint256 lockDuration){
        unlockTime=block.timestamp+lockDuration;
    }

    modifier timeUnlocked(){
        require(block.timestamp>=unlockTime,"Box is still locked");
        _;
    }

    function getBoxType() external pure override returns(string memory){
        return "Timelocked";
    }

    function getSecret() public view override onlyOwner timeUnlocked returns(string memory){
        return super.getSecret();
    }

    function getUnlockTime() external view returns(uint256){
        return unlockTime;
    }

    function getRemainingLockTime() external view returns(uint256){
        if(block.timestamp>=unlockTime) return 0;
        return unlockTime-block.timestamp;
    }

}