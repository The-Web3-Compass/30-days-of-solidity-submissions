//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract ScientificCalculator {

    // A pure function neither reads from nor modifies the blockchain state
    // while a view function can read the state but not modify it
    function power(uint256 _base, uint256 _exponent) public pure returns (uint256) {
        if (_exponent == 0) return 1;
        else return (_base ** _exponent);
    }

    function squareRoot(int256 _number) public pure returns(int256) {
        // uint allows only positive numbers
        require(_number > 0, "Cannot perform the square root of a negative number.");
        if (_number == 0) return 0;
        
        int256 result = _number / 2;
        for(int256 i = 0; i < 10; i ++) {
            result = (result + _number / result) / 2;
        }
        return result;
    }
}
