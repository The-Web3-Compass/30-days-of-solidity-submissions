// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day9ScientificCalculator.sol";

contract Calculator{
    address public owner;
    address public ScientificCalculatorAddress;  //将存储已部署的科学计算器地址

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner{
        ScientificCalculatorAddress = _address;
    }

    function add(uint256 a, uint256 b) public pure returns(uint256){
        uint256 result = a + b;
        return result;
    }

    function substract(uint256 a, uint256 b) public pure returns(uint256){
        uint256 result = a - b;
        return result;
    }

    function multiply(uint256 a, uint256 b) public pure returns(uint256){
        uint256 result = a * b;
        return result;
    }

    function divide(uint256 a, uint256 b) public pure returns(uint256){
        require(b != 0, "Cannot divide by zero");
        uint256 result = a / b;
        return result;
    }

    //从ScientificCalculator.sol中调用power幂函数
    function calculatePower(uint256 base, uint256 exponent) public view returns(uint256){
        ScientificCalculator scientificCalc = ScientificCalculator(ScientificCalculatorAddress);  //地址转换：将地址转换为合约引用
        uint256 result = scientificCalc.power(base,exponent);
        return result;
    }

    //不import的情况下调用，（如果只知道要调用函数的地址和名称） low-level调用
    function calculateSquareRoot(uint256 number) public returns(uint256){
        require(number >= 0, "Cannot calculate square root of negative number");
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);  //核心！使用abi来准备函数调用。
        //abi代表应用程序二进制接口，将其视为合约的通信协议——它定义了当一个合约调用另一个合约时必须如何构建数据。
        (bool success, bytes memory returnData) = ScientificCalculatorAddress.call(data); //
        require(success, "External call failed");

        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
// 看一下视频，scientificCalculatoraddress的地址是怎么定义的，对应的是什么，输入的是本地地址还是哈希数呢？


}
