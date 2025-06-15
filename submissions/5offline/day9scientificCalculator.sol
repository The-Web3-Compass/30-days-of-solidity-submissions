//SPDX-License-Identifier:MIT

pragma solidity^0.8.0;

 contract ScientificCalculator {
    //写两份简单合同然后把它们联合起来，调用另一个合约里的函数来做事，先写子合同
    //像是app调用另一个app，calculator是主合同，进行加减乘除
    //将进行的运算function：幂，开平方根
    function power(uint256 base, uint256 exponent)public pure returns(uint256){
        //pure像view，关键词,pure 函数 —「看都不看，只算不存」
        if(exponent ==0)return 1;
        else return (base**exponent);


    }
    function squareroot(int256 number) public pure returns(int256){
        require(number>=0, "cannot calculate square root of negative number.");
        //为什么写了number>0的require还要用int？可以直接改成uint吧
        if (number ==0)return 0;
        //power method and newton method两种方法，powermethod是迭代乘矩阵并归一化向量

        int256 result = number/2;
        //初始猜测，猜一个差不多的数字，然后开始牛顿法收敛
        for (uint256 i=0; i<10; i++){
            result =(result+number /result)/2;
            //f(x)=0方程的解，不断画切线，一直画十次 
        }
        return result;




    }

    
    




 }
