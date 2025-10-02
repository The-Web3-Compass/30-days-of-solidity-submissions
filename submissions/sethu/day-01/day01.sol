//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Day01 {
    // Function to calculate the sum of two numbers
    function sum(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    // Function to calculate the product of two numbers
    function product(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }

    // Function to calculate the difference of two numbers
    function difference(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "a must be greater than or equal to b");
        return a - b;
    }
}