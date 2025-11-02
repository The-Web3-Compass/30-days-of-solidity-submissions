//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox{

    //识别金库类型
    function getBoxType() external pure override returns(string memory){
        return "Basic";
    }
}