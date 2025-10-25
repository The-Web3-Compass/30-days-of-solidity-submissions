// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;    
// 编译版本 不要漏了分号

contract ClickCounter {
    // 括号内的所有内容都属于此合约
    // 点击计数器
    uint256 public counter;  // public 说明合约外部可以访问

    function click() public {
        counter++;
    }

    function reset() public {
        counter = 0;
    }

    function decrease() public returns (bool) {
        if (counter > 0) {
            counter--;
            return true;
        } else {
            return false;
        }
    }

    function getCounter() public view returns (uint256){
        // view 是修饰 getCounter() 的
        // Solidity 会自动生成一个同名getter函数 counter()
        return counter;
    }

    function clickMultiple(uint256 times) public {
        counter += times;
    }
}