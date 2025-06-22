// SPDX-License-Identifier:MIT

// 编译器版本
pragma solidity ^0.8.0;

// 新建合约
contract ClickCounter{
    uint256 public counter ;

    function click() public {
        counter ++;
    }
}
