// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import"./Day9-ScientificCalculator.sol";//调用科学计算器

contract Calculator{
    address public owner;
    address public scientificCalculatorAddress;
    constructor(){
        owner=msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner{
        scientificCalculatorAddress=_address;
    }

    function add(uint256 a, uint256 b) public pure returns(uint256){
        uint256 results=a+b;
        return results;
    }

    function subtract(uint256 a, uint256 b) public pure returns(uint256){
        uint256 results=a-b;
        return results;
    }

    function multiply(uint256 a, uint256 b) public pure returns(uint256){
        uint256 results=a*b;
        return results;
    }

    function divide(uint256 a, uint256 b) public pure returns(uint256){
        uint256 results=a/b;
        return results;
    }

    function calculatePower(uint256 base, uint exponent) public view returns(uint256){
         ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress); 

         uint256 results=scientificCalc.power(base, exponent);
         return results;
    }
 function calculateSquareRoot(int256 number) public view returns(int256){
         ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress); 

         int256 results=scientificCalc.squareRoot(number);
         return results;
    }

}