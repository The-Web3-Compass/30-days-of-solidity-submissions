// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

//基础计算器：基本功能
contract Calculator {
    address public owner;
    address public sciCalculatorAddress; //科学计算器的位置

    constructor( ) {
        owner=msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can perform this action");
    _;
    }

    //调用其中的函数
    function setsciCalculator(address _address)public onlyOwner{
        sciCalculatorAddress=_address;
    }
    // function getsciCalculator
    //基础函数
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a + b;
        return result;
    }
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a - b;
        return result;
    }
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a * b;
        return result;
    }
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        uint256 result = a / b;
        return result;
    }
    //高级函数
    //高级调用：导入了外部合约的代码
    function calculatePower(uint256 base,uint256 exp)public view returns (uint256){
        ScientificCalculator scientificCalc = ScientificCalculator(sciCalculatorAddress);
        uint256 result =scientificCalc.power(base,exp);
        return result;
    }
    //低级调用:abi编码函数调用
    function calculateSquareRoot(uint256 number) public  returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        //核心：手动处理-发送代码
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        (bool success, bytes memory returnData) = sciCalculatorAddress.call(data);
        require(success, "External call failed");
        //解码响应
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }

}