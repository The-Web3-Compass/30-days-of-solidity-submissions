//SPDX-License-Identifier: MIT;

pragma solidity ^0.8.19;

interface ICalculator {
    function add(uint256 a, uint256 b) external returns (uint256);
    function subtract(uint256 a, uint256 b) external returns (uint256);
    function multiply(uint256 a, uint256 b) external returns (uint256);
    function divide(uint256 a, uint256 b) external returns (uint256);
    function getCalculationCount() external view returns (uint256);
    function getCalculation(uint256 index) external view returns (tuple(string operation, uint256 a, uint256 b, uint256 result, uint256 timestamp));
}

contract SmartCalculator{
    ICalculator public calculator;

    struct UserOperation {
        string operation;
        uint256 a;
        uint256 b;
        uint256 result;
        uint256 timestamp;
        address calculatorAddress;
    }

    UserOperation[] public userOperations;
    
    event OperationPerformed(string operation, uint256 a, uint256 b, uint256 result);

    constructor(address _calculatorAddress){
        calculator = ICalculator(_calculatorAddress);
    }

    function setCalculatorAddress(address _calculatorAddress) external {
        calculator = ICalculator(_calculatorAddress);
    }

    function performAddition(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.add(a, b);
        userOperations.push(UserOperation("add", a, b, result, block.timestamp, address(calculator)));
        emit OperationPerformed("add", a, b, result);
        return result;
    }

    function performSubtraction(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.subtract(a, b);
        userOperations.push(UserOperation("subtract", a, b, result, block.timestamp, address(calculator)));
        emit OperationPerformed("subtract", a, b, result);
        return result;
    }

    function performMultiplication(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = calculator.multiply(a, b);
        userOperations.push(UserOperation("multiply", a, b, result, block.timestamp, address(calculator)));
        emit OperationPerformed("multiply", a, b, result);
        return result;
    }

    functUserOperationCount() external view returns (uint256) {
        return userOperations.length;
    }

    function getCalculatorCalculationCount() external view returns (uint256) {
        return calculator.getCalculationCount();
    }
    
    function getUserOperation(uint256 index) external view returns (UserOperation memory){
        require(index < userOperations.length, "Index out of bounds");
        return userOperations[index];
    }
}