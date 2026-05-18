// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox {
    function getBoxType() public pure override returns (string memory) {
        return "Basic";
    }
}

contract PremiumDepositBox is BaseDepositBox {
    mapping(address => string) private metadata;

    function setMetadata(address user, string calldata data) external onlyOwner {
        metadata[user] = data;
    }

    function getMetadata(address user) external view onlyOwner returns (string memory) {
        return metadata[user];
    }

    function getBoxType() public pure override returns (string memory) {
        return "Premium";
    }
}

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public unlockTime;

    uint256 public lockDurationSeconds;

        modifier timeUnlocked() {
            require(block.timestamp >= getDepositTime() + lockDurationSeconds, "Box is still time-locked");
            _;
        }

        constructor(uint256 _lockDurationSeconds) {
                require(_lockDurationSeconds > 0, "Lock duration must be > 0");
                lockDurationSeconds = _lockDurationSeconds;
                unlockTime = block.timestamp + _lockDurationSeconds;
            }

    function getSecret() public view override timeUnlocked returns (string memory) {
        return super.getSecret();
    }

    function getBoxType() public pure override returns (string memory) {
        return "TimeLocked";
    }
}

// Duplicate BasicDepositBox definition removed.

// Duplicate PremiumDepositBox definition removed.

// Duplicate TimeLockedDepositBox definition removed.