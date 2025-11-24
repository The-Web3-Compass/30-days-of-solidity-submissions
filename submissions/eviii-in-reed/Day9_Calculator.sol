//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./ScientificCalculator.sol";

contract Calculator {
    address public owner;
    address public scientificCalculatorAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access Denied");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a + b;
        return result;
    }

    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a - b;
        return result;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a * b;
        return result;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Zero division error.");
        uint256 result = a / b;
        return result;
    }

    function calculatePower(uint256 base, uint256 exponent) public view returns(uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress); // 1st ScientificCalculator is a datatype
        uint256 result = scientificCalc.power(base, exponent); // .power() is from ScientificCalculator
        return result;
    }

    function calculateSquareRoot(uint256 number) public returns(uint256) {
        require(number >= 0, "Cannot calculate square root for negative numbers.");
        
        // ABI: Application Binary Interface, convert into bytes
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);  // call a function, send a number
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data); // .call() returns 2 pieces of data
        require(success, "Unable to call square root function.");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
        // The previous method is easier but requires to know the exact function signature .power()
        // This .call() method is more flexible - can call any function even if no contract’s interface imported
    }
}
