//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./day14BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox{

    function getBoxType() external pure override returns(string memory){
        return "Basic";
    }
}