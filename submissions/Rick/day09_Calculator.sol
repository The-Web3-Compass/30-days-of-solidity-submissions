// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day09_ScientificCalculator.sol";

contract Calculator{

    address private owner;
    address private scientificCalculatorAddress;

    constructor (){
        owner = msg.sender;
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
         _; 
    }
    //设置 setScientificCalculator 合约地址
    function setScientificCalculator(address _addr) public onlyOwner{
        scientificCalculatorAddress = _addr;
    }

    /*
        高级调用
        创建合约B的对象，参数是B的合约地址，然后就可以调用B中的方法
        会自动实现abi编码
        请求失败会自动revert
        安全性高
        适合正常函数调用

        pure修饰要求
        不能读取或修改链上数据，一般用于数据运算
        view，不能修改只能读取链上数据
    */
    function calculatePower(uint a,uint b) public view  returns ( uint){
        ScientificCalculator culator = ScientificCalculator(scientificCalculatorAddress);
        uint sum = culator.add(a,b);
        return sum;
    }

    /*
        低级调用
        abi是solidity内置的编码库
        abi.encodeWithSignature的作用是将函数签名和请求参数组装为请求报文，供低级调用call使用
        使用call方法发送请求报文，返回参数有成功失败的状态值和返回数据的字节数组
        用abi解析返回字节数组，解析为方法正确的返回

        注意：写方法签名时，uint 改为uint256
        在 Solidity 编译阶段，uint == uint256；
        在 ABI 编码阶段，签名字符串中必须写 uint256，否则选择器不匹配
    */
    function calculateSquareRoot(uint a , uint b) public   returns ( uint){
        bytes memory data = abi.encodeWithSignature("add(uint256,uint256)", a,b);
        (bool success , bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, unicode"低级调用失败");
        uint sum= abi.decode(returnData, (uint));
        return sum;
    }
}