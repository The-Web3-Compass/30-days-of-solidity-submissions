// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint256 private counter;

    // 增加计数（单次）
    function increment() public {
        counter += 1;
    }

    // 一次增加多次（带溢出保护）
    function clickMultiple(uint256 times) public {
        // Solidity 0.8+ 自动检查溢出，但显式 require 更清晰
        require(times > 0, "Times must be greater than 0");
        counter += times;
    }

    // 重置计数
    function reset() public {
        counter = 0;
    }

    // 获取当前计数（view 函数）
    function getCounter() public view returns (uint256) {
        return counter;
    }
