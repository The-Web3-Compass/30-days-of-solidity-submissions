 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator {
     
  address public owner;
  address public scientificCalculatorAddress;

   
modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can perform this action");
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
    require(b != 0, "Cannot divide by zero");
    uint256 result = a / b;
    return result;
}



function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
    ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
    uint256 result = scientificCalc.power(base, exponent);
    return result;
}


  }



