// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { IDepositBox } from "./IDepositBox.sol";
import { IOwnable } from "./IOwnable.sol";
import { Ownable } from "./Ownable.sol";

/**
 * @title DepositBox
 * @dev Build a smart bank that offers different types of deposit boxes — basic, premium, time-locked, etc.
 * Each box follows a common interface and supports ownership transfer.
 * A central VaultManager contract interacts with all deposit boxes in a unified way,
 * letting users store secrets and transfer ownership like handing over the key to a digital locker.
 * This teaches interface design, modularity, and how contracts communicate with each other safely.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 14
 */
abstract contract DepositBox is IDepositBox, IOwnable, Ownable {
    uint256 public createTime;
    string private secret;

    constructor() Ownable() {
        createTime = block.timestamp;
    }

    function saveSecret(string memory newSecret) public onlyOwner virtual override {
        secret = newSecret;
    }

    function readSecret() public view onlyOwner virtual override returns(string memory) {
        return secret;
    }
}
