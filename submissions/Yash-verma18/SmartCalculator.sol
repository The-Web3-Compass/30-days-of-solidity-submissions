// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calculator {
  
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }
}

// Main contract caller 
contract SmartCalculator {
    Calculator public calculator; 

    constructor(address calculatorAddress) {
        calculator = Calculator(calculatorAddress);
    }
    function getProduct(uint256 x, uint256 y) public view returns (uint256) {
        return calculator.multiply(x, y);
    }
    function getDifference(uint256 x, uint256 y) public view returns (uint256) {
        return calculator.subtract(x, y);
    }
    function getQuotient(uint256 x, uint256 y) public view returns (uint256) {
        return calculator.divide(x, y);
    }

    function getSum(uint256 x, uint256 y) public view returns (uint256) {
        return calculator.add(x, y);
    }
}
