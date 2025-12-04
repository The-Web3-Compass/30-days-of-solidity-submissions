//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract scientificCalculator{
}
    function power(uint256 base, uint256 exponent) public oure returns (uint256) {
        if (exponent ==0) return 1;
        else return base ** exponent;
    }
    function squreRoot(uint256 number) public pure returns (uint256) {
        require(number >=0, "Input must be non-negativebnumber");
        if (number == 0 || number == 1) {
            return number;
        int256 result = number / 2;
        for (uint i = 0 ; i < 10; i++) {
            result = (result  + number / result) / 2;
        }
        return uint256(result);
    }
    function 