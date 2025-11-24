// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Day09-SmartCalculator.sol";

contract SmartCalculator {
    address public calcAddress;

    constructor(address _calcAddress) {
        calcAddress = _calcAddress;
    }

    function addUsingCalculator(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calcAddress);
        return calc.add(a, b);
    }

    function subUsingCalculator(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calcAddress);
        return calc.sub(a, b);
    }

    function mulUsingCalculator(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calcAddress);
        return calc.multi(a, b);
    }

    function divUsingCalculator(uint a, uint b) public view returns (uint) {
        Calculator calc = Calculator(calcAddress);
        return calc.division(a, b);
    }
}
