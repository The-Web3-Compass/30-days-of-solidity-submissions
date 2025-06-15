// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicCalculator {
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "Result cannot be negative");
        return a - b;
    }
    
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }
    
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b > 0, "Cannot divide by zero");
        return a / b;
    }
}

contract SmartCalculator {
    address public basicCalculatorAddress;
    
    constructor(address _calculatorAddress) {
        basicCalculatorAddress = _calculatorAddress;
    }
    
    function performAddition(uint256 a, uint256 b) external view returns (uint256) {
        BasicCalculator calculator = BasicCalculator(basicCalculatorAddress);
        return calculator.add(a, b);
    }
    
    function performSubtraction(uint256 a, uint256 b) external view returns (uint256) {
        BasicCalculator calculator = BasicCalculator(basicCalculatorAddress);
        return calculator.subtract(a, b);
    }
    
    function performMultiplication(uint256 a, uint256 b) external view returns (uint256) {
        BasicCalculator calculator = BasicCalculator(basicCalculatorAddress);
        return calculator.multiply(a, b);
    }
    
    function performDivision(uint256 a, uint256 b) external view returns (uint256) {
        BasicCalculator calculator = BasicCalculator(basicCalculatorAddress);
        return calculator.divide(a, b);
    }
    
    function complexCalculation(uint256 a, uint256 b) external view returns (uint256) {
        BasicCalculator calculator = BasicCalculator(basicCalculatorAddress);
        
        uint256 sum = calculator.add(a, b);
        uint256 product = calculator.multiply(a, b);
        
        if (sum > product) {
            return calculator.subtract(sum, product);
        } else {
            return calculator.divide(product, sum);
        }
    }
    
    function changeCalculatorAddress(address newAddress) external {
        basicCalculatorAddress = newAddress;
    }
}
