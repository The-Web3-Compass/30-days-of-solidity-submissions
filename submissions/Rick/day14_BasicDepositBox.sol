// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14_BaseDepositBox.sol";

// 常规box
contract BasicDepositBox is BaseDepositBox {

    
    
    function getBoxType() external pure returns (string memory){
        return unicode"普通box";
    }

}