// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Calculator.sol";

contract SmartCalculator {
    Calculator public calculator;
    address public calculatorAddress;
    address public owner;

    // Event to log calculation results
    event CalculationResult(
        string operation,
        uint256 a,
        uint256 b,
        uint256 result
    );

    constructor(address _calculatorAddress) {
        require(_calculatorAddress != address(0), "Invalid calculator address");
        calculatorAddress = _calculatorAddress;
        calculator = Calculator(_calculatorAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Function to perform addition using the Calculator contract
    function performAddition(uint256 a, uint256 b) public returns (uint256) {
        uint256 result = calculator.add(a, b);
        emit CalculationResult("Addition", a, b, result);
        return result;
    }

    // Function to perform subtraction using the Calculator contract
    function performSubtraction(uint256 a, uint256 b) public returns (uint256) {
        uint256 result = calculator.subtract(a, b);
        emit CalculationResult("Subtraction", a, b, result);
        return result;
    }

    // Function to perform multiplication using the Calculator contract
    function performMultiplication(
        uint256 a,
        uint256 b
    ) public returns (uint256) {
        uint256 result = calculator.multiply(a, b);
        emit CalculationResult("Multiplication", a, b, result);
        return result;
    }

    // Function to perform division using the Calculator contract
    function performDivision(uint256 a, uint256 b) public returns (uint256) {
        uint256 result = calculator.divide(a, b);
        emit CalculationResult("Division", a, b, result);
        return result;
    }

    // Function to update the calculator address
    function updateCalculatorAddress(address _newCalculatorAddress) public {
        require(
            _newCalculatorAddress != address(0),
            "Invalid calculator address"
        );
        calculatorAddress = _newCalculatorAddress;
        calculator = Calculator(_newCalculatorAddress);
    }

    function power(
        uint256 base,
        uint256 exponent
    ) public pure returns (uint256) {
        if (exponent == 0) return 1;
        else return (base ** exponent);
    }

    function squareRoot(uint256 number) public pure returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        if (number == 0) return 0;

        uint256 result = number / 2;
        for (uint256 i = 0; i < 10; i++) {
            result = (result + number / result) / 2;
        }
        return result;
    }
}
