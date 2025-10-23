// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./09-scientificCalculator.sol";

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

    //设置科学记数器地址
    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;

    }

    //简单加法
    function add(uint256 a, uint256 b) public pure returns (uint256){
        uint256 result = a + b;
        return result;

    }

    //简单减法
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a - b;
        return result;

    }

    //简单乘法
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a * b;
         return result;

    }

    //简单除法
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "divide number cannot be zero");
        uint256 result = a / b;
        return result;

    }

    //调用方式1
    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        uint256 result = scientificCalc.power(base, exponent);
        return result;

    }

    //调用方式2,比较低级的方式
    function calculateSquareRoot(uint256 number) public view returns (uint256) {
        require(number >= 0, "Cannot calculate square root of nagetive number");
        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);

        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;

    }

}

