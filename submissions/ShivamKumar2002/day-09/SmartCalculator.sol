// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Calculator
/// @author shivam
/// @notice A simple contract to simulate a calculator.
contract Calculator {
    /// @notice Address of contract owner
    /// @dev This can be another smart contract.
    address private owner;

    /// @notice Error thrown when caller is not owner of contract
    error NotOwner();

    /// @notice Initializes te contract by setting the owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Ensures that caller is owner of the contract.
    /// @custom:error NotOwner if caller is not the owner.
    modifier ownerOnly {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    /// @notice Add A and B
    function add(int a, int b) external view ownerOnly returns (int) {
        return a + b;
    }

    /// @notice Subtract B from A
    function subtract(int a, int b) external view ownerOnly returns (int) {
        return a - b;
    }

    /// @notice Multiply A by B
    function multiply(int a, int b) external view ownerOnly returns (int) {
        return a * b;
    }

    /// @notice Divide A by B
    function divide(int a, int b) external view ownerOnly returns (int) {
        return a / b;
    }

    /// @notice Get remainder of division of A by B
    function remainder(int a, int b) external view ownerOnly returns (int) {
        return a % b;
    }
}

/// @title SmartCalculator
/// @author shivam
/// @notice A simple contract that calls a Calculator contract to perform calculations.
contract SmartCalculator {
    /// @notice Reference to Calculator contract deployed specifically for this contract.
    Calculator private calculator;

    /// @notice Error thrown when given operator is invalid
    /// @param operator Operator
    error InvalidOperator(bytes8 operator);

    /// @notice Constants for supported operations.
    /// Supported operators are ADD, SUBTRACT, MULTIPLY, DIVIDE and REMAINDER.
    bytes8 public constant ADD = "+";
    bytes8 public constant SUBTRACT = "-";
    bytes8 public constant MULTIPLY = "*";
    bytes8 public constant DIVIDE = "/";
    bytes8 public constant REMAINDER = "%";

    /// @notice Initializes the contract by deploying a new Calculator contract.
    constructor() {
        calculator = new Calculator();
    }

    /// @notice Perform calculation based on operator
    /// @param a First number
    /// @param b Second number
    /// @return result Result of calculation
    /// @custom:error InvalidOperator if operator is unknown.
    function calculate(bytes8 operator, int a, int b) external view returns (int) {
        if (operator == ADD) {
            return calculator.add(a, b);

        } else if (operator == SUBTRACT) {
            return calculator.subtract(a, b);

        } else if (operator == MULTIPLY) {
            return calculator.multiply(a, b);

        } else if (operator == DIVIDE) {
            return calculator.divide(a, b);

        } else if (operator == REMAINDER) {
            return calculator.remainder(a, b);

        } else {
            revert InvalidOperator(operator);
        }
    }
}