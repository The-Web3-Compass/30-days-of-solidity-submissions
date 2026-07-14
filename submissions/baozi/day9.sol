// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calculator {
    address public immutable owner;
    address public scientificCalculatorAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    /// @notice Set the address of the ScientificCalculator contract
    function setScientificCalculator(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        scientificCalculatorAddress = _address;
    }

    /// @notice Add two numbers
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    /// @notice Subtract second number from first
    function subtract(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }

    /// @notice Multiply two numbers
    function multiply(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    /// @notice Divide first number by second
    function divide(uint256 a, uint256 b) external pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }

    /// @notice Calculate power using ScientificCalculator
    function calculatePower(uint256 base, uint256 exponent) external view returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");
        return ScientificCalculator(scientificCalculatorAddress).power(base, exponent);
    }

    /// @notice Calculate square root using low-level call to ScientificCalculator
    function calculateSquareRoot(uint256 number) external returns (uint256) {
        require(scientificCalculatorAddress != address(0), "ScientificCalculator not set");

        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", int256(number));
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);

        require(success, "External call to squareRoot failed");
        return abi.decode(returnData, (uint256));
    }
}