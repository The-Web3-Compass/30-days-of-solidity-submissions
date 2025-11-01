// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract scientificCalculator{
    //pure 不读取区块链任何内容，仅做数学计算
    function power(uint256 base,uint256 exponent) public pure returns(uint256){
        if(exponent ==0 )return 0;
        else return (base ** exponent);
    }

    function squareRoot(int256 number) public pure returns(int256){
        require(number >=0,"cannot calculate square root of negative number");
        if(number ==0) return 0;
        int256 result =number/2;
        for(uint256 i =0;i<5;i++){
            result =(result + number /result)/2;
        }
        return result;
    }
}
