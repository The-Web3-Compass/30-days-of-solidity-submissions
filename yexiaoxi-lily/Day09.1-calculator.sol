// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./scientificCalculator.sol";


contract calculator{
    address public owner;
    address public scientificCalculatorAddress;

    constructor(){
        owner =msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"only owner can do this action");
        _;
    }

    function setScientificCalculator(address _address)public onlyOwner{
        scientificCalculatorAddress = _address;
    }

    function add(uint256 a,uint256 b)public pure returns(uint256){
        uint256 result =a+b;
        return result;
    }

    function subtract(uint256 a,uint256 b)public pure returns(uint256){
        uint256 result =a-b;
        return result;
    }

    function multiply(uint256 a,uint256 b)public pure returns(uint256){
        uint256 result =a*b;
        return result;
    }

    function divide(uint256 a,uint256 b)public pure returns(uint256){
        require(b!=0,"cannot divide by zero");
        uint256 result =a/b;
        return result;
    }
    //合约与合约间的高层调用，类型安全的方法
    function calculatePower(uint256 base,uint256 exponent)public view returns(uint256){
        //将以太坊地址转换为合约，顶部已经导入合约，solidity知道了合约结构，允许调用
        scientificCalculator scientificCalc =scientificCalculator(scientificCalculatorAddress);
        //调用合约中的power函数
        uint256 result = scientificCalc.power(base,exponent);
        return result;
    }
    //低级调用，不导入其源代码交互（只知道函数地址和名称），灵活但风险高
    function calculatateSquareRoot(uint256 number) public returns(uint256){
        require(number >=0,"cannot calculate square root of negative number");
        //编码函数调用   字节数组储存bytes m d   应用程序二进制接口abi.ews    函数签名sqr   发送出去的值number
        bytes memory data =abi.encodeWithSignature("squareRoot(int256)",number);
        //将数据发送存储在sccalAdd地址中，返回布尔值成功与否和字节数组（函数返回内容）
        (bool success,bytes memory returnData)=scientificCalculatorAddress.call(data);
        require(success,"External call failed");
        //将squRoot返回的int类型转为unit类型
        uint256 result =abi.decode(returnData,(uint256));
        return result;
    }

}
