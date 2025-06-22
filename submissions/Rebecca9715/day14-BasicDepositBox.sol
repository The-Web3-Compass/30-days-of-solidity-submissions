  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

// 引入base函数，继承关系
contract BasicDepositBox is BaseDepositBox {
    // pure表示不读取任何内存storage，输出为硬编码string
    // override: It’s overriding the abstract getBoxType() function declared in IDepositBox (and left unimplemented in BaseDepositBox).
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}

