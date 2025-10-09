// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./BasicMath.sol";

contract SmartCalculator {
    address public mathContract;

    constructor(address _mathContract) {
        mathContract = _mathContract;
    }

    function add(uint a, uint b) public view returns (uint) {
        return BasicMath(mathContract).add(a, b);
    }

    function subtract(uint a, uint b) public view returns (uint) {
        return BasicMath(mathContract).subtract(a, b);
    }

    function multiply(uint a, uint b) public view returns (uint) {
        return BasicMath(mathContract).multiply(a, b);
    }

    function divide(uint a, uint b) public view returns (uint) {
        return BasicMath(mathContract).divide(a, b);
    }
}
