// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { IDepositBox } from "./IDepositBox.sol";
import { DepositBox } from "./DepositBox.sol";

/**
 * @title BasicDepositBox
 */
contract BasicDepositBox is DepositBox {
    constructor() DepositBox() {}

    function getType() public pure override returns(string memory) {
        return "basic";
    }
}
