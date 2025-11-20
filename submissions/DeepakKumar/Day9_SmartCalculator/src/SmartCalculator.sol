// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Calculator.sol";

/// @title SmartCalculator - Uses Calculator contract for math operations
contract SmartCalculator {
    Calculator public calculator;

    event CalculationResult(string operation, uint256 result);

    constructor(address _calculatorAddress) {
        calculator = Calculator(_calculatorAddress);
    }

    function addNumbers(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.add(a, b);
        emit CalculationResult("Addition", result);
        return result;
    }

    function subtractNumbers(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.subtract(a, b);
        emit CalculationResult("Subtraction", result);
        return result;
    }

    function multiplyNumbers(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.multiply(a, b);
        emit CalculationResult("Multiplication", result);
        return result;
    }

    function divideNumbers(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.divide(a, b);
        emit CalculationResult("Division", result);
        return result;
    }
}
