// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day9Part1.sol";

contract Calculator{

    address public owner;
    address public scientificCalculatorAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;
    }

    // 加法
    function add(uint256 a, uint256 b) public pure returns(uint256) {
        return a + b;
    }

    // 减法
    function subtract(uint256 a, uint256 b) public pure returns(uint256) {
        return a - b;
    }

    // 乘法
    function multiply(uint256 a, uint256 b) public pure returns(uint256) {
        return a * b;
    }

    // 除法
    function divide(uint256 a, uint256 b) public pure returns(uint256) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }

    function calcPower(uint256 base, uint256 exponent) public view returns(uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        // 外部调用
        return scientificCalc.power(base, exponent);
    }

    // 低级调用实现求平方根运算
    function calcSqrt(uint256 number) public returns(uint256) {
        require(number >= 0, "Cannot calculate square root of negative nmber");
        // ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        // 低级调用
        // (bool success, bytes memory data) = address(scientificCalc).staticcall(abi.encodeWithSignature("sqrt(uint256)", number));
        // require(success, "Failed to call sqrt function");
        // return abi.decode(data, (uint256));
        bytes memory data = abi.encodeWithSignature("sqrt(int256)", number);
        (bool success, bytes memory result) = scientificCalculatorAddress.call(data);
        require(success, "Failed to call sqrt function in ScientificCalculator");
        return abi.decode(result, (uint256));
    }
}