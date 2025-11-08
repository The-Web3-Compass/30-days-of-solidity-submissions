// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day09 ScientificCalculator.sol";

contract Calculator {
    address public owner;
    address public scientificCalculatorAddress;
    uint256 public basicCalculationCount;
    uint256 public lastResult;
    
    event BasicCalculation(string operation, uint256 result);
    event AdvancedCalculation(string operation, uint256 result);
    event ScientificCalculatorSet(address calculatorAddress);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // 设置科学计算器地址
    function setScientificCalculator(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        scientificCalculatorAddress = _address;
        emit ScientificCalculatorSet(_address);
    }
    
    // ========== 基础数学函数 ==========
    
    function add(uint256 a, uint256 b) external returns (uint256) {
        basicCalculationCount++;
        uint256 result = a + b;
        lastResult = result;
        
        emit BasicCalculation("add", result);
        return result;
    }
    
    function subtract(uint256 a, uint256 b) external returns (uint256) {
        require(a >= b, "Result cannot be negative");
        
        basicCalculationCount++;
        uint256 result = a - b;
        lastResult = result;
        
        emit BasicCalculation("subtract", result);
        return result;
    }
    
    function multiply(uint256 a, uint256 b) external returns (uint256) {
        basicCalculationCount++;
        uint256 result = a * b;
        lastResult = result;
        
        emit BasicCalculation("multiply", result);
        return result;
    }
    
    function divide(uint256 a, uint256 b) external returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        
        basicCalculationCount++;
        uint256 result = a / b;
        lastResult = result;
        
        emit BasicCalculation("divide", result);
        return result;
    }
    
    // ========== 高级数学函数 (委托给ScientificCalculator) ==========
    
    function calculatePower(uint256 base, uint256 exponent) external returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");
        
        ScientificCalculator sciCalc = ScientificCalculator(scientificCalculatorAddress);
        uint256 result = sciCalc.power(base, exponent);
        
        lastResult = result;
        emit AdvancedCalculation("power", result);
        
        return result;
    }
    
    function calculateSquareRoot(uint256 number) external returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");
        
        ScientificCalculator sciCalc = ScientificCalculator(scientificCalculatorAddress);
        uint256 result = sciCalc.sqrt(number);
        
        lastResult = result;
        emit AdvancedCalculation("sqrt", result);
        
        return result;
    }
    
    function calculateFactorial(uint256 n) external returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");
        
        ScientificCalculator sciCalc = ScientificCalculator(scientificCalculatorAddress);
        uint256 result = sciCalc.factorial(n);
        
        lastResult = result;
        emit AdvancedCalculation("factorial", result);
        
        return result;
    }
    
    // ========== 实用函数 ==========
    
    function getLastResult() external view returns (uint256) {
        return lastResult;
    }
    
    function getBasicCalculationCount() external view returns (uint256) {
        return basicCalculationCount;
    }
    
    function getTotalCalculationCount() external view returns (uint256) {
        if (scientificCalculatorAddress == address(0)) {
            return basicCalculationCount;
        }
        
        ScientificCalculator sciCalc = ScientificCalculator(scientificCalculatorAddress);
        return basicCalculationCount + sciCalc.getCalculationCount();
    }
}