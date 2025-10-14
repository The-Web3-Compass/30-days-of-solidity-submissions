// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { IDepositBox } from "./IDepositBox.sol";
import { DepositBox } from "./DepositBox.sol";

/**
 * @title TimeLockedDepositBox
 */
contract TimeLockedDepositBox is DepositBox {
    uint256 public lockedUntil;

    constructor(uint256 lockDuration) DepositBox() {
        lockedUntil = block.timestamp + lockDuration;
    }

    function getType() public pure override returns(string memory) {
        return "timeLocked";
    }
    
    function readSecret() public view onlyOwner virtual override returns(string memory) {
        require(block.timestamp >= lockedUntil, "deposit box still under time lock");
        return super.readSecret();
    }
}
