// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator {
    // basic math functions}
    address public owner;
    address public scientificCalculatorAddress;// address of the already-deployed ScientificCalculator

    constructor() {
        owner = msg.sender;
    }
 
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;
    }

    //add(a, b)
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a + b;
        return 
            result;
    }
    //subtract(a, b)
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a - b;
        return 
            result;
    }
    //multiply(a, b)
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a * b;
        return 
            result;
    }
    //divide(a, b)
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        uint256 result = a / b;
        return 
            result;
    }
    //calculatePower(base, exponent)，Address Casting
    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        uint256 result = scientificCalc.power(base, exponent);
        //uint256 result = ScientificCalculator(scientificCalculatorAddress).power(base, exponent);
        return 
            result;
    }

    //low level call of calculateSquareRoot(number)
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return 
            result;
    }
}
