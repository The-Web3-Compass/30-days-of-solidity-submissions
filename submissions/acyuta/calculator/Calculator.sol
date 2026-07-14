// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ScientificCalculator} from "./ScientificCalculator.sol";

contract Calculator {
    // can use 1. interface - treat as object
    // 2. abi encode - low level call when no address? but fujnction signature
    address public owner;
    address public scientificCalculatorAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner {
        require(_address != address(0), "Invalid calculator address");
        require(_address.code.length > 0, "Address is not a contract");
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

    // interface
    function calculatePower(
        uint256 base,
        uint256 exponent
    ) public view returns (uint256) {
        require(
            scientificCalculatorAddress != address(0),
            "Scientific calculator not set"
        );
            scientificCalculatorAddress
        );
        return scientificCalculator.power(base, exponent);
    }

    // low-level
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        (bool success, bytes memory returnData) = scientificCalculatorAddress
            .call(abi.encodeWithSignature("squareRoot(uint256)", number));
        require(success, "External call failed");
        return abi.decode(returnData, (uint256));
    }
}
