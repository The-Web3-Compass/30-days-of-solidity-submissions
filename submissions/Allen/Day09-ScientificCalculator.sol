// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;


contract ScientificCalculator{

    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0){
            return 1;
        } else {
            return (base ** exponent);
        }
    }


    function squareRoot(uint256 number)public pure returns(int256){
        require(number >= 0,"Invaild number");
        if (number == 0) return 0;
        // TODO 
        int256 result = number / 2;

        for(uint256 i ; i < 10 ; i++){
            result = (result + number / result) / 2;
        }

        return result;

    }

    

}