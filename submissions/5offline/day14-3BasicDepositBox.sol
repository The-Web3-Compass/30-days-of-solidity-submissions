// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";
//先导入原来的合约

contract BasicDepositBox is BaseDepositBox {

    function getBoxType() external pure override returns (string memory) {
        return "Basic";
        //   //报告自己盒子是什么类型
    }
}