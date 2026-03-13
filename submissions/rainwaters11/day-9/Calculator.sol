// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";
import "./StatisticsCalculator.sol";

contract Calculator {
    address public owner;
    address public scientificCalculatorAddress;
    address public statsCalculatorAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // --- Contract Linking ---
    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;
    }

    function setStatsCalculator(address _address) public onlyOwner {
        statsCalculatorAddress = _address;
    }

    // --- Basic Math (Internal) ---
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

    // --- Interface Calls (Type-Safe) ---
    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        require(scientificCalculatorAddress != address(0), "Calculator not set");
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        return scientificCalc.power(base, exponent);
    }

    // EXTENDED CHALLENGE: Interface call to the Statistics contract
    function calculateAverage(uint256[] memory numbers) public view returns (uint256) {
        require(statsCalculatorAddress != address(0), "Stats calculator not set");
        StatisticsCalculator statsCalc = StatisticsCalculator(statsCalculatorAddress);
        return statsCalc.calculateMean(numbers);
    }

    // --- Low-Level Call (Dynamic) ---
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        require(scientificCalculatorAddress != address(0), "Calculator not set");

        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);

        require(success, "External call failed");
        return abi.decode(returnData, (uint256));
    }
}
