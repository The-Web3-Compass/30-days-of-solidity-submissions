// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This is the helper contract that performs actual calculations
contract Calculator {
    function add(uint a, uint b) external pure returns (uint) {
        return a + b;
    }

    function subtract(uint a, uint b) external pure returns (uint) {
        return a - b;
    }

    function multiply(uint a, uint b) external pure returns (uint) {
        return a * b;
    }

    function divide(uint a, uint b) external pure returns (uint) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }
}

// This is the main contract that interacts with Calculator
contract SmartCalculator {
    address public calculatorAddress; // Address of deployed Calculator contract

    constructor(address _calculatorAddress) {
        calculatorAddress = _calculatorAddress;
    }

    // Function to interact with the Calculator contract
    function addNumbers(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calculatorAddress); 
        return calc.add(a, b);
    }

    function subtractNumbers(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calculatorAddress);
        return calc.subtract(a, b);
    }

    function multiplyNumbers(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calculatorAddress);
        return calc.multiply(a, b);
    }

    function divideNumbers(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calculatorAddress);
        return calc.divide(a, b);
    }
}
