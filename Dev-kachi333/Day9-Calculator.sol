// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./ScientificCalculator.sol";

contract calculator{
    address public  owner;
    address public scientificCalculatorAddress;

    constructor () {
        owner=msg.sender;
    }

     
modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can perform this action");
    _;
}

//set scientific calculator address
 
function setScientificCalculator(address _address) public onlyOwner {
    scientificCalculatorAddress = _address;
}

//Addition
 
function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 result = a + b;
    return result;
}


//Subtraction
 
function subtract(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 result = a - b;
    return result;
}



//Multiplication
 
function multiply(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 result = a * b;
    return result;
}

//Division
 
function divide(uint256 a, uint256 b) public pure returns (uint256) {
    require(b != 0, "Cannot divide by zero");
    uint256 result = a / b;
    return result;
}



//Connecting to another contract
function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
    ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
    uint256 result = scientificCalc.power(base, exponent);
    return result;
}

//using low level calls


function calculateSquareRoot(uint256 number) public returns (uint256) {
    require(number >= 0, "Cannot calculate square root of negative number");

    bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
    (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
    require(success, "External call failed");

    uint256 result = abi.decode(returnData, (uint256));
    return result;
}






}

