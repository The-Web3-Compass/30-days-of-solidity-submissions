// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day_14_BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox {
    // A view function can read blockchain state but cannot modify it.
    // A pure function can neither read nor modify any blockchain state — it only uses local data or parameters.
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}

