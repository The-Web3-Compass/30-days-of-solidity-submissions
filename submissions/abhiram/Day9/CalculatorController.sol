// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// CalculatorController does the actual math
contract CalculatorController {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        require(b <= a, "Underflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) external pure returns (uint256) {
        require(b != 0, "Division by zero");
        return a / b;
    }
}
