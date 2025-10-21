// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calculator {
    function add(int a, int b) public pure returns (int) {
        return a + b;
    }

    function sub(int a, int b) public pure returns (int) {
        return a - b;
    }

    function mul(int a, int b) public pure returns (int) {
        return a * b;
    }

    function div(int a, int b) public pure returns (int) {
        require(b != 0, "No divide by zero");
        return a / b;
    }
}
