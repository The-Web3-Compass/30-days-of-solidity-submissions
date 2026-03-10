// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ScientificCalculator{


    function power(uint256 base, uint256 exponent) public pure returns(uint256) {
        if (exponent == 0) return 1; 
        else return (base ** exponent);
        
    }


    function squareRoot(int256 number) public pure returns(int256){
        require(number>=0, "Cannot calculate square root of negative number");
        if(number == 0) return 0;


    
    }



}