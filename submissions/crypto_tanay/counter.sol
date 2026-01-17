// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract counter{
    uint256 public number;

    function click() public {
        number += 1;
    }
    function get() public view returns (uint256) {
        return number;
    }
}