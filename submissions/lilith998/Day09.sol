// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Calculator Contract (Deploy this first)
contract Calculator {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
    
    function subtract(uint256 a, uint256 b) external pure returns (uint256) {
        require(a >= b, "Calculator: Subtraction underflow");
        return a - b;
    }
    
    function multiply(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }
    
    function divide(uint256 a, uint256 b) external pure returns (uint256) {
        require(b > 0, "Calculator: Division by zero");
        return a / b;
    }
}

// Interface for the Calculator contract
interface ICalculator {
    function add(uint256 a, uint256 b) external pure returns (uint256);
    function subtract(uint256 a, uint256 b) external pure returns (uint256);
    function multiply(uint256 a, uint256 b) external pure returns (uint256);
    function divide(uint256 a, uint256 b) external pure returns (uint256);
}

// Calling Contract (Uses the Calculator contract)
contract MathOperations {
    ICalculator public calculator;
    address public owner;
    
    event CalculationPerformed(
        string operation,
        uint256 a,
        uint256 b,
        uint256 result
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can set calculator");
        _;
    }
    
    constructor(address calculatorAddress) {
        owner = msg.sender;
        setCalculator(calculatorAddress);
    }
    
    function setCalculator(address calculatorAddress) public onlyOwner {
        // Cast the address to the ICalculator interface type
        calculator = ICalculator(calculatorAddress);
    }
    
    function performAddition(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.add(a, b);
        emit CalculationPerformed("ADD", a, b, result);
        return result;
    }
    
    function performSubtraction(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.subtract(a, b);
        emit CalculationPerformed("SUB", a, b, result);
        return result;
    }
    
    function performMultiplication(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.multiply(a, b);
        emit CalculationPerformed("MUL", a, b, result);
        return result;
    }
    
    function performDivision(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.divide(a, b);
        emit CalculationPerformed("DIV", a, b, result);
        return result;
    }
    function complexCalculation(uint256 a, uint256 b) public view returns (uint256) {
    // Demonstrates multiple contract calls
    return calculator.divide(calculator.multiply(a, b), calculator.add(a, b));
    }
}