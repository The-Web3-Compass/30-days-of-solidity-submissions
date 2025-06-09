// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RealCalculator.sol";

// Primary contract that delegates calculations to RealCalculator
contract SmartCalculator {
    // Address of the RealCalculator contract
    address private realCalculator;

    // Constructor to set the RealCalculator contract address
    constructor(address _realCalculator) {
        realCalculator = _realCalculator;
    }

    // Calls add function on RealCalculator
    function add(uint256 a, uint256 b) public view returns (uint256) {
        return RealCalculator(realCalculator).add(a, b);
    }

    // Calls subtract function on RealCalculator
    function subtract(uint256 a, uint256 b) public view returns (uint256) {
        return RealCalculator(realCalculator).subtract(a, b);
    }

    // Calls multiply function on RealCalculator
    function multiply(uint256 a, uint256 b) public view returns (uint256) {
        return RealCalculator(realCalculator).multiply(a, b);
    }

    // Calls divide function on RealCalculator
    function divide(uint256 a, uint256 b) public view returns (uint256) {
        return RealCalculator(realCalculator).divide(a, b);
    }

    // Calls power function on RealCalculator
    function power(
        uint256 base,
        uint256 exponent
    ) public view returns (uint256) {
        return RealCalculator(realCalculator).power(base, exponent);
    }

    // Calls root function on RealCalculator
    function root(uint256 a, uint256 n) public view returns (uint256) {
        return RealCalculator(realCalculator).root(a, n);
    }
}
