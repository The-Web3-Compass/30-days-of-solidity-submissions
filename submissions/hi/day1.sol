// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint256 public counter;			// 状态变量 - 存储点击次数
    
    function click() public {		// 函数 - 增加计数器
        counter++;
    }														
}
