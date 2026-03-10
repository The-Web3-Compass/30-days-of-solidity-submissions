// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract SmartCalculator {

    ScientificCalculator public calculator;

    constructor(address _calculatorAddress) {
        calculator = ScientificCalculator(_calculatorAddress);
    }

    function addNumbers(uint a, uint b) public view returns(uint) {
        return calculator.add(a,b);
    }

    function subtractNumbers(uint a, uint b) public view returns(uint) {
        return calculator.subtract(a,b);
    }

    function multiplyNumbers(uint a, uint b) public view returns(uint) {
        return calculator.multiply(a,b);
    }

    function divideNumbers(uint a, uint b) public view returns(uint) {
        return calculator.divide(a,b);
    }
}