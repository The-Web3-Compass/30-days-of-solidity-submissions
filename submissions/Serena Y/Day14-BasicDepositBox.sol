// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-BaseDepositBox.sol";

//contract BasicDepositBox is BaseDepositBox {
    //function getBoxType() external pure override returns (string memory) {
        //return "Basic";
    //}
//}

 contract BasicDepositBox is BaseDepositBox {
    constructor(address initialOwner,address initialManager)
    BaseDepositBox(initialOwner,initialManager) { }
    function getBoxType() external pure override returns (string memory) { return "Basic"; } }
