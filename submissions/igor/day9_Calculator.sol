// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day9_ScientificCalculator.sol";

contract Calculator{
    address public owner;
    address public scientificCalculatorAddress;
    ScientificCalculator scientificCalc;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can do!");
        _;
    }

    function setScientificCalculator(address _addr) public onlyOwner{
        scientificCalculatorAddress = _addr;
        scientificCalc = ScientificCalculator(_addr);
    } 

    function add(uint256 a,uint256 b) public pure returns(uint256){
        return a+b;
    }

    function subtract(uint256 a,uint256 b) public pure returns(uint256){
        return a-b;
    }

    function multiply(uint256 a,uint256 b) public pure returns(uint256){
        return a*b;
    }

    function divide(uint256 a,uint256 b) public pure returns(uint256){
        require(b != 0,"cannot divide by 0");
        return a/b;
    }

    function calculatePower(uint256 base,uint256 expoente) public view returns(uint256){
        //external call 
        uint256 result = scientificCalc.power(base, expoente);

        return result;

    }
    function calculateSquareRoot(uint256 number)public view returns (int256){
        require(number >= 0, "number negative");
        return scientificCalc.quadradoRoot(int256(number));
    }
    
}