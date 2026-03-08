// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {

    uint256 public counter;

    // 点击一次
    function click() public {
        counter++;
    }

    // 重置为0
    function reset() public {
        counter = 0;
    }

    // 减1（防止变成负数）
    function decrease() public {
        require(counter > 0, "Counter already 0");
        counter--;
    }

    // 一次增加多次
    function clickMultiple(uint256 times) public {
        counter += times;
    }
}
