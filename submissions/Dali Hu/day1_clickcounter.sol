// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    // 状态变量 - 存储点击次数
    uint256 public counter;

    // 函数 - 增加计数器
    function click() public {
        counter++;
    }
}