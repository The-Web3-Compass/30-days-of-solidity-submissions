// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Clicker {

    uint256 public clickCount;

    function click() external {
        clickCount += 1;
    }
}

