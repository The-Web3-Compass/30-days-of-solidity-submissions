// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Calculator.sol";

contract SmartCalculator {
    address public calculatorAdd;

    constructor(address _calculatorAdd) {
        require(_calculatorAdd != address(0), "Calculator address cannot be zero");
        calculatorAdd = _calculatorAdd;
    }

    function calAdd(uint256 value1, uint256 value2) public returns (uint256) {
        Calculator calc = Calculator(calculatorAdd);
        return calc.add(value1, value2);
    }

    function calSub(uint256 value1, uint256 value2) public returns (uint256) {
        Calculator calc = Calculator(calculatorAdd);
        return calc.sub(value1, value2);
    }

    function calMultipy(uint256 value1, uint256 value2) public returns (uint256) {
        Calculator calc = Calculator(calculatorAdd);
        return calc.multiply(value1, value2);
    }

    function calDivide(uint256 value1, uint256 value2) public returns (uint256) {
        Calculator calc = Calculator(calculatorAdd);
        return calc.divide(value1, value2);
    }

    function power(uint value, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) return 1;
        else return (value ** exponent);
    }

    function getResultValue() public view returns (uint256) {
        Calculator calc = Calculator(calculatorAdd);
        return calc.getResult();
    }

    
}
