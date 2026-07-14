// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contract that performs calculations
contract Calculator {

    function add(uint a, uint b) public pure returns (uint) {
        return a + b;
    }

    function subtract(uint a, uint b) public pure returns (uint) {
        return a - b;
    }

    function multiply(uint a, uint b) public pure returns (uint) {
        return a * b;
    }

    function divide(uint a, uint b) public pure returns (uint) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }
}


// Contract that calls another contract
contract SmartCalculator {

    address public calculatorAddress;

    constructor(address _calculatorAddress) {
        calculatorAddress = _calculatorAddress;
    }

    // Call add function from Calculator contract
    function addNumbers(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calculatorAddress);
        return calc.add(a, b);
    }

    // Call subtract function
    function subtractNumbers(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calculatorAddress);
        return calc.subtract(a, b);
    }

    // Call multiply function
    function multiplyNumbers(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calculatorAddress);
        return calc.multiply(a, b);
    }

    // Call divide function
    function divideNumbers(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calculatorAddress);
        return calc.divide(a, b);
    }
}