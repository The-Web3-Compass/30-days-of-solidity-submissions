// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
   Build a contract that uses another contract to do calculations. 
   You'll learn how contracts can talk to each other by calling 
   functions of other contracts (using `address casting`). 
   It's like having one app ask another app to do some math, 
   showing how to interact with other contracts.
*/

contract SmartCalculator{
  
    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) return 1;
        else return (base ** exponent);
    }
    
    function squareRoot(uint256 _number) public pure returns (uint256) {
        require(_number >= 0, "Cannot calculate square root of negative number");
        if (_number == 0) return 0;

        uint256 result = _number / 2;
        for (uint256 i = 0; i < 10; i++) {
            result = (result + _number / result) / 2;
        }
        return result;
    }
}

