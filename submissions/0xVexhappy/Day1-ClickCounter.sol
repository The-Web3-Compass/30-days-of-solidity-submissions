// SPDX-License-Identifier: MIT
// @author 0xVexhappy

pragma solidity ^0.8.18;

contract ClickCounter{
    uint256 public counter;

    function click() public{
        counter++;
    }
}
