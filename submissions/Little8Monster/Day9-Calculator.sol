// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day9-ScientificCalculator.sol";

contract Calculator{
    address public owner;
    address public scientificCalculatorAddress;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can do this action");
        _;
    }

    //该函数会保存该地址，以便我们之后可以调用它的函数
    function setScientificCalculator(address _address)public onlyOwner{
        scientificCalculatorAddress = _address;
    }

    //基础数学函数
    //加法
    //pure不能读状态变量，只能用参数计算
    function add(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a+b;
        return result;
    }

    //减法
    function substract(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a-b;
        return result;
    }

    //乘法
    function multiply(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a*b;
        return result;
    }

    //除法
    function divide(uint256 a,uint256 b)public pure returns(uint256){
        require(b!= 0, "Cannot divide by zero");
        uint256 result = a/b;
        return result;
    }


    //连接到另一个合约：幂函数
    function calculatorPower(uint256 base, uint256 exponent)public view returns(uint256){
    ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
    //合约的类型ScientificCalculator
    //现在创建的变量名scientificCalc
    //ScientificCalculator(scientificCalculatorAddress)，告诉 Solidity：“这个地址上部署的是 ScientificCalculator 合约，请按它的接口来操作。”
    
    //调用这个合约中的 power() 函数。
    uint256 result = scientificCalc.power(base, exponent);

    return result;
    }

    //使用低级调用
    function calculatorSquareRoot(uint256 number)public returns (uint256){
        require(number >= 0, "Cannot calculate square root of negative number");

        //ABI 代表应用程序二进制接口 。可以看作是合同的"通信协议"——它定义了当一方合同调用另一方时数据必须如何结构化
        //squareRoot(int256)要调用的目标函数的“签名”，包括函数名 + 参数类型（必须完全匹配）
        //number传入的实际参数，会一并被编码进 data
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        //.call() 的返回值：一个布尔值表示是否执行成功，一个字节数组表示返回的数据
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }


}