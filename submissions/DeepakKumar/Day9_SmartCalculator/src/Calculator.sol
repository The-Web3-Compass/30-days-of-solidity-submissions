// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Calculator - Basic arithmetic contract
contract Calculator {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    function subtract(uint256 a, uint256 b) external pure returns (uint256) {
        require(a >= b, "Underflow error");
        return a - b;
    }

    function multiply(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    function divide(uint256 a, uint256 b) external pure returns (uint256) {
        require(b != 0, "Division by zero");
        return a / b;
    }
}

