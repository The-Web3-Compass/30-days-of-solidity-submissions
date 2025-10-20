// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day9-Calculator.sol";

contract SmartCalculator {
    Calculator public calculator;

    constructor(address _calculatorAddr) {
        calculator = Calculator(_calculatorAddr);
    }

    function addNumbers(int a, int b) public view returns (int) {
        return calculator.add(a, b);
    }

    function subNumbers(int a, int b) public view returns (int) {
        return calculator.sub(a, b);
    }

    function mulNumbers(int a, int b) public view returns (int) {
        return calculator.mul(a, b);
    }

    function divNumbers(int a, int b) public view returns (int) {
        return calculator.div(a, b);
    }
}
