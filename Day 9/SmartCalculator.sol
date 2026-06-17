// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasicMath.sol";

contract SmartCalculator {
    address public mathContract;

    constructor(address _mathAddress) {
        mathContract = _mathAddress;
    }

    function calculateSum(uint a, uint b) public view returns (uint) {
        return BasicMath(mathContract).add(a, b);
    }

    function calculateProduct(uint a, uint b) public view returns (uint) {
        return BasicMath(mathContract).multiply(a, b);
    }
}
