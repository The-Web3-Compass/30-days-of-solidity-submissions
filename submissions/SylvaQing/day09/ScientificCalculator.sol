// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//科学计算器：高级功能
contract ScientificCalculator {
    //幂次计算
    function power(uint256 base,uint256 exp)public pure returns (uint256){
        if(exp==0) return 1;
        else return (base ** exp);
    }
    //开根计算
    function sqrRoot(uint256 num)public pure returns (uint256){
        require(num >= 0, "Cannot calculate square root of negative number");
        if (num == 0) return 0;

        //牛顿法
        uint256 result =num/2;
        for (uint256 i=0;i<10;i++){
            result =(result+num/result)/2;
        }
        return result;

    }
}