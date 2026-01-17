//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator {
    address public owner;
    address public scientificCalculatorAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Link the deployed ScientificCalculator contract
    function setScientificCalculator(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        scientificCalculatorAddress = _address;
    }

    // Basic math (pure)
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

    // High-level typed call to ScientificCalculator.power
    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");
        ScientificCalculator sci = ScientificCalculator(scientificCalculatorAddress);
        return sci.power(base, exponent);
    }

    // Low-level ABI-encoded call to ScientificCalculator.squareRoot
    function calculateSquareRoot(uint256 number) public view returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");

        // Encode function signature and argument
        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);

        // Perform low-level call
        (bool success, bytes memory returnData) = scientificCalculatorAddress.staticcall(data);
        require(success, "External call failed");

        // Decode return value
        return abi.recode(returnData, (uint256));
    }
}