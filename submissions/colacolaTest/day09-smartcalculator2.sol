//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./day09-ScientificCalculator.sol";

contract SmartCalculator{

    address public owner;
    ScientificCalculator public calculator;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner can perform this action.");
        _;
    }

    function setScientificCalculatorAddress(address _address) public onlyOwner{
        calculator = ScientificCalculator(_address);
    }


    function add(int256 a, int256 b) public pure returns(int256){
        return (a+b);
    }

    function subtract(int256 a, int256 b) public pure returns(int256){
        return (a-b);
    }

    function multiply(int256 a, int256 b) public pure returns(int256){
        return (a*b);
    }

    function divide(int256 a, int256 b) public pure returns(int256){
        require(b != 0, "Division by zero is not allowed.");
        return (a/b);
    }

    function calculatepower(uint256 base, uint256 exponent) public view returns(uint256){ 
        return calculator.power(base, exponent);
        }

    function calculateSquareRoot(uint256 number) public view returns(uint256){
        return calculator.squareRoot(number);
    }
}
