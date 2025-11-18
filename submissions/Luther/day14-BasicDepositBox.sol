// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

//这个函数告诉外部调用者：:该合约是一个 “Basic”（基础版）存款盒，与 PremiumDepositBox（高级版）区分开
contract BasicDepositBox is BaseDepositBox {
    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}