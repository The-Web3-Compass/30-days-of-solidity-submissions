// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox {
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}

contract PremiumDepositBox is BaseDepositBox {
    mapping(string => string) public metadata;
    
    function setMetadata(string memory key, string memory value) external onlyOwner {
        metadata[key] = value;
    }
    
    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }
}

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public unlockTime;
    
    constructor(uint256 _lockDuration) {
        unlockTime = block.timestamp + _lockDuration;
    }
    
    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime, "Still locked");
        _;
    }
    
    function getSecret() public view override timeUnlocked returns (string memory) {
        return super.getSecret();
    }
    
    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }
}