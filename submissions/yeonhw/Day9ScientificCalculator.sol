// SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract ScientificCalculator{
    
    //幂
    function power(uint256 base, uint256 exponent) public pure returns(uint256){
        if(exponent == 0) return 1;
        else return (base ** exponent);
    }

    //平方根
    function squareRoot(uint256 number) public pure returns(uint256){
        require(number >= 0, "Cannot calculate square root of negative n number.");
        if(number == 0) return 0;

        uint256 result = number / 2;  //向下取整，截断
        for(uint256 i = 0; i < 10; i++){
            result = (result + number / result) / 2;
        }
        return result;
    }

    
}
