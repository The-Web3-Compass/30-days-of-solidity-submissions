// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public immutable lockDuration;

    constructor(uint256 _lockDuration) {
        require(_lockDuration > 0, "Lock duration must be greater than 0");
        lockDuration = _lockDuration;
    }

    function getSecret() public view override onlyOwner returns (string memory) {
        require(block.timestamp >= getDepositTime() + lockDuration, "Secret is time-locked");
        return super.getSecret();
    }
    }

    function getBoxType() public pure override returns (string memory) {
        return "TIME_LOCKED_DEPOSIT_BOX";
    }
}
