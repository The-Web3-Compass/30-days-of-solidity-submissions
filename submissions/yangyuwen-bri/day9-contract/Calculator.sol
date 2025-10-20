//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator{
    address public owner;
    address public scientificCalculatorAddress;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can perform this action.");
        _;
    }

    //设置地址
    function setScientificCalculatorAddress(address _address) public onlyOwner{
        scientificCalculatorAddress = _address;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a + b;
        return result;
    }

    function substract(uint256 a, uint256 b) public pure returns (uint256) {
        require(a > b, "a must greater than b.");
        uint256 result = a - b;
        return result;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a * b;
        return result;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        uint256 result = a / b;
        return result;
    }

    function calculatePower(uint256 base, uint256 exponent) public view returns(uint256) {
        
        //利用sci的地址声明一个变量、再调用
        ScientificCalculator ScientificCalc = ScientificCalculator(scientificCalculatorAddress);
        uint256 result = ScientificCalc.power(base, exponent);
        return result;

    }

    // Low-Level Calls
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");
        
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    
    }



}