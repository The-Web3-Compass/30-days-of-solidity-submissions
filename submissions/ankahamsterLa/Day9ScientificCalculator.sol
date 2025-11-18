//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;


// Design calculator to handle basic math: addition,subtraction,multiplication and division.
contract ScientificCalculator{


    //The funtion is marked "pure" because it doesn't read or change anything on the blockchain.
    function power(uint256 base,uint256 exponent) public pure returns(uint256){
        if(exponent==0)return 1;
        else return (base**exponent);
    }

    // Take a classical technique called Newton's Method to find square roots through repeated approximations.
    function squareRoot(int256 number) public pure returns(int256){
        require(number>=0,"Cannot calculate square root of negative number");
        if(number==0)return 0;

        int256 result=number/2;
        for(uint256 i=0;i<10;i++){
            result=(result+number/result)/2;
        }

        return result;
    }


}