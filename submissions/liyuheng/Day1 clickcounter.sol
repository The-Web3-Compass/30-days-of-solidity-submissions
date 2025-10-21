// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@title 点击计数器合约
///@author yuheng
///@notice 此合约用以记录点击按钮的次数
///@dev 用于solidity教学

contract ClickCounter {

    ///@notice 声明了一个只能存放正整数的全局的公开计数器的变量
    uint256 public counter;

    ///@notice 函数 点击 公开调用，每调用一次，该函数会将点击计数器 +1
    /// @dev 没有限制调用者，也没有 Gas 限制，适合教学或测试
    function click() public {
        counter ++;
    }

}