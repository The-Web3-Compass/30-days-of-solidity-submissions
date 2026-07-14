// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Calculator {
    function add(uint a, uint b) public pure returns (uint) {
        return a + b;
    }

    function sub(uint a, uint b) public pure returns (uint) {
        return a - b;
    }

    function multi(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }

    function division(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Division by zero");
        return a / b;
    }
}
