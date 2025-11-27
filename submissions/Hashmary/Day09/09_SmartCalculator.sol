/*---------------------------------------------------------------------------
  File:   09_SmartCalculator.sol
  Author: Marion Bohr
  Date:   04/09/2025
  Description:
    Build a contract that uses another contract to do calculations. You'll 
    learn how contracts can talk to each other by calling functions of other 
    contracts (using `address casting`). It's like having one app ask another
    app to do some math, showing how to interact with other contracts.
    -------------------------
    Concepts You'll Master: 
        Calling functions of another contract
        address casting
        imports
    Learning Progression:
        Introduces inter-contract communication

----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SmartCalculator {
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "No negative results");
        return a - b;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Division by zero");
        return a / b;
    }
}    

// in case you separate the coding into two files:
// import "./SmartCalculator.sol";

contract CalculatorSystem {
    address public calculatorAddress;

    constructor(address _calculatorAddress) {
        calculatorAddress = _calculatorAddress;
    }

    function performAddition(uint256 x, uint256 y) public view returns (uint256) {
        SmartCalculator calc = SmartCalculator(calculatorAddress);
        return calc.add(x, y);
    }

    function performSubtraction(uint256 x, uint256 y) public view returns (uint256) {
        SmartCalculator calc = SmartCalculator(calculatorAddress);
        return calc.subtract(x, y);
    }

    function performMultiplication(uint256 x, uint256 y) public view returns (uint256) {
        SmartCalculator calc = SmartCalculator(calculatorAddress);
        return calc.multiply(x, y);
    }

    function performDivision(uint256 x, uint256 y) public view returns (uint256) {
        SmartCalculator calc = SmartCalculator(calculatorAddress);
        return calc.divide(x, y);
    }

    // Update calculator address if needed
    function updateCalculator(address _newAddress) public {
        calculatorAddress = _newAddress;
    }
}
