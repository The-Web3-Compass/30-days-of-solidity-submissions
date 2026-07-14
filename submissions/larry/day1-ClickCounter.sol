// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint256 public clickCount;
    function click() public {
        clickCount++;
    }
}