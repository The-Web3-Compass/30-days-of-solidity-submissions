  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14_BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox {
    constructor(address _owner) BaseDepositBox(_owner){
    }
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}
