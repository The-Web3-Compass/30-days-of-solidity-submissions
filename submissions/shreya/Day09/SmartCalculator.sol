// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.0;

contract Calc{
    function power(uint256 base, uint256 exponent) public pure returns(int256){
        if(exponent == 0) return 1;
        else return(base ** exponent);
    }
    // not returning 
    function sqRoo(int256 num) public pure returns(uint256){
        require(num >0 , "Cannot calculate sq root of negative");
        if(num == 0) return 0;
        int256 res  = num/2;
        for (uint256 i = 0; i<10 , i++){
            res = (res + num / res) /2 ;
        }
        return res;
    }
}