// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./day9_1.sol";

contract Calculator {

    address public manager;
    address public scientificCalculator;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner{
        scientificCalculator = _address;
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
    
    /**
     * external call
     * 
     * @param base the base of the power
     * @param exponent the exponent of the power
     * @return the power of the base and exponent
     */
    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        ScientificCalculator sc = ScientificCalculator(scientificCalculator);
        return sc.power(base, exponent);
    }

    /**
     * low level call
     * 
     * @param number the number to calculate the square root of
     * @return the square root of the number
     */
    function calculateSquareRoot(uint256 number) public view returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");

        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);
        (bool success, bytes memory returnData) = scientificCalculator.call(data)
        require(success, "External call failed");

        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
}