// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    // 状态变量 - 存储点击次数
    uint256 public counter;

    // 函数 - 增加计数器
    function click() public {
        counter++;
    }

    // 函数 - 实现reset功能
    function reset() public {
        counter = 0;
    }
    
    // 函数 - 计数器次数减1
    function decrease() public {
        counter--;
    }

    // 函数 - 返回当前次数
    function getCounter() public view returns (uint) {
        return counter;
    }   

    // 函数 - 添加自定义次数
    function clickMultiple(uint256 times) public {
        counter += times;
    }
}