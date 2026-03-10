// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract SmartCalculator {
    address public owner;
    ScientificCalculator public scientificCalculator;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculator = ScientificCalculator(_address);
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }

    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        return scientificCalculator.power(base, exponent);
    }

    function calculateSquareRoot(uint256 number) public view returns (uint256) {
        return scientificCalculator.squareRoot(number);
    }
}