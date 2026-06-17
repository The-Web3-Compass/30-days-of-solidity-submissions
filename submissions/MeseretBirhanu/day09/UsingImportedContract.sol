// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./SmartCalculator.sol";

contract UsingImportedContract{
    SmartCalculator public calc;

    constructor(address calcAddress){
        calc = SmartCalculator(calcAddress);
    }


    function addition(uint256 a , uint256 b) public view  returns(uint256){
        return calc.add(a, b);
    }

    function subtraction(uint256 a , uint256 b) public view returns(uint256){
        return calc.subtract(a, b);
    }
    
    function multiplication(uint256 a , uint256 b) public view  returns(uint256){
        return calc.multiply(a, b);
    }
     function division(uint256 a , uint256 b) public view  returns(uint256){
        return calc.divide(a, b);
    }   
}