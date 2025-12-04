// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ScientificCalculator {

    function power(uint256 _base, uint256 _exponent) public pure returns (uint256) {
        return _base ** _exponent;
    }

    function squareRoot(int256 _number)public pure returns(int256){
        require(_number >= 0, "Cannot calculate square root of negative number");
        if(_number == 0)return 0;

        int256 result = _number/2;
        for(uint256 i = 0; i<10; i++){
            result = (result + _number / result)/2;
        }

        return result;

    }
}