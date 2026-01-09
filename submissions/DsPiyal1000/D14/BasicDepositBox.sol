// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox {
    function getBoxType() public pure override returns (string memory) {
        return "Basic";
    }
}