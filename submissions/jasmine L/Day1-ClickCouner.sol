// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter{
    // 定义状态变量 counter
    // 无需写查询函数，因为 counter 变量是公有？
    uint256 public counter;

    /*
    函数名称：计数器
    功能：每次调用该函数时，状态变量 counter 自动计数（+1）
    */
    function click() public {
        counter++;
    }
    /*
    函数名称：重置
    功能：每次调用该函数时，状态变量 counter 重置为0
    */
    function reset() public {
        counter = 0;
    }
    /*
    函数名称：计数器-减
    功能：每次调用该函数时，状态变量 counter 自动计数（-1）
    */
    function decrease() public{
        require(counter > 0, "Counter: cannot decrease below zero");
        counter--; 
        
    }
    /*
    函数名称：查看
    功能：查看当前计数值
    */
    function getCounter() public view returns (uint256) {
        return counter;
    }
    
    /*
    函数名称：多次计数器
    功能：按照发送值，来增加计数器的值
    */
    function clickMultiple(uint256 times) public {
        counter += times;
    }

}
