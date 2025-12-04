// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ClickCounter {
    uint256 public counter;
    function btnClick() public {
        counter++;
    }
}