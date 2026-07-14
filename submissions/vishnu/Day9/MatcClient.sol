// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICalculator {
    function add(uint256 a, uint256 b) external pure returns (uint256);
    function multiply(uint256 a, uint256 b) external pure returns (uint256);
}

contract MathClient {
    address public calculatorAddress;

    constructor(address _calculatorAddress) {
        calculatorAddress = _calculatorAddress;
    }

    function useAddition(uint256 x, uint256 y) external view returns (uint256) {
        return ICalculator(calculatorAddress).add(x, y);
    }

    function useMultiplication(uint256 x, uint256 y) external view returns (uint256) {
        return ICalculator(calculatorAddress).multiply(x, y);
    }
}