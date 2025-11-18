// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Calculator {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    function subtract(uint256 a, uint256 b) external pure returns (uint256) {
        require(a >= b, "Calculator: underflow");
        return a - b;
    }

    function multiply(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    function divide(uint256 a, uint256 b) external pure returns (uint256) {
        require(b != 0, "Calculator: division by zero");
        return a / b;
    }
}

interface ICalculator {
    function add(uint256 a, uint256 b) external pure returns (uint256);
    function subtract(uint256 a, uint256 b) external pure returns (uint256);
    function multiply(uint256 a, uint256 b) external pure returns (uint256);
    function divide(uint256 a, uint256 b) external pure returns (uint256);
}

contract MathManager {
    ICalculator public immutable calculator;
    event CalculationPerformed(string operation, uint256 result);

    constructor(address _calculator) {
        require(_calculator != address(0), "Invalid calculator address");
        calculator = ICalculator(_calculator);
    }

    function performAddition(uint256 a, uint256 b) external returns (uint256 result) {
        result = calculator.add(a, b);
        emit CalculationPerformed("Addition", result);
    }

    function performSubtraction(uint256 a, uint256 b) external returns (uint256 result) {
        result = calculator.subtract(a, b);
        emit CalculationPerformed("Subtraction", result);
    }

    function performMultiplication(uint256 a, uint256 b) external returns (uint256 result) {
        result = calculator.multiply(a, b);
        emit CalculationPerformed("Multiplication", result);
    }

    function performDivision(uint256 a, uint256 b) external returns (uint256 result) {
        result = calculator.divide(a, b);
        emit CalculationPerformed("Division", result);
    }
}
