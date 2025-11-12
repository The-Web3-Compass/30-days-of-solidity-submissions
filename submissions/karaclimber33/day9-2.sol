//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
//计算器，需要功能有加减乘除，幂函数，平方根计算
//把功能分为两部分，基础计算器部分：加减乘除。导入科学计算器：幂函数、平方根

import "./ScientificCalculator.sol";

contract Calculator{
    //基础变量定义
    address owner;
    address scientificCalculatorAddress;
    //构造函数初始化
    constructor(){
        owner=msg.sender;
    }
    //标识符小警察
    modifier onlyOwner{
        require(msg.sender==owner,"You are not the owner!");
        _;
    }
    //登记调用合约地址
    //提问，为什么要登记合约地址？既然要在这里登记合约地址那么为什么还需要在最上面导入这个合约
    function setScientficCalculatorAddress(address _address)public onlyOwner{
        scientificCalculatorAddress=_address;
    }

    //加
    function add(uint256 a,uint256 b)public pure returns(uint256){
        return a+b;

    }
    //减
    //要小心A>B
    function subject(uint256 a,uint256 b)public pure returns(uint256){
        return a-b;
    }
    //乘
    function multiply(uint256 a,uint256 b)public pure returns(uint256){
        return a*b;
    }
    //除
    function devide(uint256 a,uint256 b)public pure returns(uint256){
        require(b!=0,"cannot devide by 0");
        uint256 result=a/b;
        return result;
    }


    //幂函数，调用高级计算器合约
    function calculatePower(uint256 base,uint256 exponent)public view returns(uint256){
        ScientificCalculator scientificCalc=ScientificCalculator(scientificCalculatorAddress);
       
        uint256 result=scientificCalc.power(base,exponent);//外部响应
       
        return result;
    }

    //低级调用平方根运算
    function calculateSquareRoot(uint256 number)public returns(uint256){
        require(number>0,"Cannot calculate square root of negative nmber");

        //bytes memory data =abi.ecodeWithSignature("squareRoot(int256)",number);

        bytes memory data=abi.encodeWithSignature("squareRoot(uint256)",number);
        (bool success,bytes memory returnData)=scientificCalculatorAddress.call(data);
        require(success,"call to scientific calculator failed");
        uint256 result=abi.decode(returnData,(uint256));
        return result;

    }
    
    



}
