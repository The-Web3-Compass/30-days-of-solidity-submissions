// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

// 可直接部署的具体合约：继承基础合约的所有功能
contract BasicDepositBox is BaseDepositBox {
    // 实现接口的getBoxType()：标识为“Basic”类型
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}