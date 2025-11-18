// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// 最简单的扩展,对 BaseDepositBox继承，实现未实现的函数
import "./BaseDepositBox.sol";
contract BasicDepositBox is BaseDepositBox {
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}