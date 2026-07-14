// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ClickCounter {
    uint256 public counter;

    function click() public {
        counter++;
    }

    function getCount() public view returns (uint256) {
        return counter;
    }
}
