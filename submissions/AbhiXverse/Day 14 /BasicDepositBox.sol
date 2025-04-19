// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import "./BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox { 

    constructor(address _owner) {
    owner = _owner;
    depositTime = block.timestamp;
}

    function getBoxType() external pure override returns (string memory) {
        return "Basic Deposit Box";
    }
}