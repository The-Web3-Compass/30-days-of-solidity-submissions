//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator{

    address public owner;
    address public scientificCalculatorAddress;
    ScientificCalculator public scientificCalc;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
         _; 
    }

    function setScientificCalculator(address _address)public onlyOwner{
        scientificCalculatorAddress = _address;
        scientificCalc = ScientificCalculator(scientificCalculatorAddress);

        }

    function add(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a+b;
        return result;
    }

    function subtract(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a-b;
        return result;
    }

    function multiply(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a*b;
        return result;
    }

    function divide(uint256 a, uint256 b)public pure returns(uint256){
        require(b!= 0, "Cannot divide by zero");
        uint256 result = a/b;
        return result;
    }

    function calculatePower(uint256 base, uint256 exponent)public view returns(uint256){
        //external call 
        uint256 result = scientificCalc.power(base, exponent);

        return result;
    }

    function calculateSquareRoot(uint256 number)public returns (uint256){
        require(number >= 0 , "Cannot calculate square root of negative nmber");

        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }


    function calculateSquareRoot_(uint256 _number) view  public returns (uint256){
        require(_number >= 0 , "Cannot calculate square root of negative nmber");
        uint256 result = scientificCalc.squareRoot(_number);
        return result;
    }

    
}