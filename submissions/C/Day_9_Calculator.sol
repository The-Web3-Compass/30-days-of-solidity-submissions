
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day_9_ScientificeCalculator.sol";

contract Caculator{
    address public owner;
    address public scientificCalculatorAddress;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner{
        scientificCalculatorAddress = _address;
    }
    // 加
    function add(uint256 a, uint256 b) public pure returns(uint256){
        uint256 result = a+b;
        return result;
    }
    // 减
    function subtract(uint256 a, uint256 b) public pure returns(uint256){
        uint256 result = a-b;
        return result;
    }
    // 乘
    function multiply(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a*b;
        return result;
    }
    // 除
    function divide(uint256 a, uint256 b)public pure returns(uint256){
        require(b != 0, "Cannot divide by zero");
        uint256 result = a/b;
        return result;
    }

    // 从别的合约进行引入调用
    function calulatePower(uint256 base, uint256 exponent) public view returns(uint256){
        // 转换合约对象进行交互
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        uint256 result = scientificCalc.power(base, exponent);
        return result;
    }
    // 低级调用，只需要知道被调用函数地址及名称
    function calculateSquareRoot(uint256 number) public returns (uint256){
        // 不支持负数
        require(number >= 0, "Cannot calculate square root of negative number");

        // 对函数调用进行编码 新概念abi， 定义一个函数调用另一个函数，数据必须如何进行构建
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        // 进行调用
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data); // 将data数据发送到scientificCalculatorAddress存储的地址
        require(success, "External call failed");

        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
}