//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./BaseDepositBox.sol";

// 继承基础型抽象合约的所有内容，用于扩展
contract BasicDepositBox is BaseDepositBox{

    // 识别金库类型:给金库打标签，用于金库的前端仪表板、VaultManager 合约中的排序逻辑、链上分析
    // external：此函数仅用于从合约外部调用（例如，从另一个合约或前端）
    // pure：它不读取或写入任何存储——它只是返回一个硬编码的字符串。
    // override：它（当前函数）正在重写在 IDepositBox中声明的抽象getBoxType()函数（并且该函数在BaseDepositBox中未被实现）。
    function getBoxType() external pure override returns(string memory){
        return "Basic";
    }
}