//SPDX-License-Identifier：MIT
//声明代码使用 MIT 许可证（开源许可证，允许自由使用/修改/分发）。

pragma solidity ^0.8.0;
//指定 Solidity 编译器版本为 0.8.0 或更高.

contract ClickCounter{
    uint256 public counter;

    function click() public{
        counter ++;
    }

}