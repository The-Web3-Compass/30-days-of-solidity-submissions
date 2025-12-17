// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Clicker {
    uint256 public clickCount;

    function click() public {
        clickCount += 1;
    }

    function decrement() public {
        clickCount -= 1;
    }

    function reset() public {
        clickCount = 0;
    }
}