//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day9-part1.sol";     //导入另一个 Solidity 文件中的合约定义
contract Calculator{

    address public owner;
    address public scientificCalculatorAddress;

    constructor(){     //定义构造函数
        owner = msg.sender;     //将部署者的地址设为合约拥有者
    }

    modifier onlyOwner() {     //定义一个函数修饰符（modifier）
        require(msg.sender == owner, "Only owner can do this action");    // 验证调用者是否是 owner
        _;     表示被修饰的函数逻辑将在此处执行
    }

    function setScientificCalculator(address _address)public onlyOwner{         //设置科学计算器合约的地址
        scientificCalculatorAddress = _address;     //保存外部合约地址
    }

    function add(uint256 a, uint256 b)public pure returns(uint256){         //定义加法函数
        uint256 result = a + b;     //计算加法
        return result;     //返回计算结果
    }

    function subtract(uint256 a, uint256 b)public pure returns(uint256){     //定义减法函数
        uint256 result = a - b;     //执行减法
        return result;     //返回计算结果
    }

    function multiply(uint256 a, uint256 b)public pure returns(uint256){     //定义乘法函数
        uint256 result = a * b;     //执行乘法运算
        return result;     //返回计算结果
    }


    function divide(uint256 a, uint256 b)public pure returns(uint256){     //定义除法函数
        require(b!= 0, "Cannot divide by zero");     //防止除以零
        uint256 result = a / b;     //执行整数除法（结果向下取整）
        return result;     //返回计算结果
    }

    function calculatePower(uint256 base, uint256 exponent)public view returns(uint256){     //通过调用外部 ScientificCalculator 合约来计算幂次方

        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);     //在当前上下文中创建一个外部合约实例

        //外部合约调用
        uint256 result = scientificCalc.power(base, exponent);     //调用外部合约的 power() 函数

        return result;     //返回调用结果
    }

    function calculateSquareRoot(uint256 number)public returns (uint256){     //调用外部合约的平方根函数
        require(number >= 0 , "Cannot calculate square root of negative number");     //防止负数输入

        bytes memory data = abi.encodeWithSignature("squareRoot(int256)",number);     //使用 ABI 编码构建调用数据
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);     //执行低级外部合约调用
        require(success, "External call failed");     //确认外部调用成功
        uint256 result = abi.decode(returnData, (uint256));     //解码外部返回的字节数据
        return result;     //返回最终的平方根结果

    }

}