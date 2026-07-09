//SPDX-License-Identifier:MIT;

pragma solidity ^0.8.19;

contract Calculator{
    struct Calculation{
        string operation;
        uint256 a;
        uint256 b;
        uint256 result;
        uint256 timestamp;
    }

    Calculation[] public calculations;

    event CalculationPerformed(string operation, uint256 a, uint256 b, uint256 result);

    function add(uint256 a, uint256 b) external returns (uint256){
        uint256 result = a+b;
        calculations.push(Calculation("add", a, b, result, block.timestamp));
        emit CalculationPerformed("add", a, b, result);
        return result;
    }

    function subtract(uint256 a, uint256 b) external returns (uint256) {
        require(b <= a, "Subtraction would underflow");
        uint256 result = a - b;
        calculations.push(Calculation("subtract", a, b, result, block.timestamp));
        emit CalculationPerformed("subtract", a, b, result);
        return result;
    }

    function multiply(uint256 a, uint256 b) external returns (uint256) {
        uint256 result = a * b;
        calculations.push(Calculation("multiply", a, b, result, block.timestamp));
        emit CalculationPerformed("multiply", a, b, result);
        return result;
    }

    function divide(uint256 a, uint256 b) external returns (uint256) {
        require(b > 0, "Cannot divide by zero");
        uint256 result = a / b;
        calculations.push(Calculation("divide", a, b, result, block.timestamp));
        emit CalculationPerformed("divide", a, b, result);
        return result;
    }

    function getCalculationCount() external view returns (uint256) {
        return calculations.length;
    }

    function getCalculation(uint256 index) external view returns (Calculation memory){
        require(index < calculations.length, "Index out of bounds");
        return calculations[index];
    }
}