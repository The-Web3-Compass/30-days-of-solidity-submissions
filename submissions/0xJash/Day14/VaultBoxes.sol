// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox {
    constructor(address _owner) BaseDepositBox(_owner) {}

    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}

contract PremiumDepositBox is BaseDepositBox {
    mapping(string => string) public metadata;

    constructor(address _owner) BaseDepositBox(_owner) {}

    function setMetadata(string memory key, string memory value) external onlyOwner {
        metadata[key] = value;
    }

    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }
}

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public unlockTime;

    constructor(uint256 duration, address _owner) BaseDepositBox(_owner) {
        unlockTime = block.timestamp + duration;
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