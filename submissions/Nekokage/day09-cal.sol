//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract SimpleCalculator {
    

    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
      
    // 加法函数
    function add(uint256 a, uint256 b) public pure returns(uint256) {
        return a + b;
    }
    
    // 减法函数
    function subtract(uint256 a, uint256 b) public pure returns(uint256) {
        return a - b;
    }
    
    // 乘法函数
    function multiply(uint256 a, uint256 b) public pure returns(uint256) {
        return a * b;
    }
    
    // 除法函数
    function divide(uint256 a, uint256 b) public pure returns(uint256) {
        require(b != 0, "不能除以零"); // 防止除以零错误
        return a / b;
    }
    
    function calculatePower(uint256 base, uint256 exponent) public pure returns(uint256) {
        require(exponent <= 10, "指数太大，请使用更小的数字");
        
        uint256 result = 1;
        for(uint256 i = 0; i < exponent; i++) {
            result = result * base;
        }
        return result;
    }
    
    function calculateSquareRoot(uint256 number) public pure returns(uint256) {
        require(number > 0, "数字必须大于0");
        
        if(number == 1) return 1;
        
        uint256 result = number;
        for(uint256 i = 0; i < 10; i++) { // 迭代10次获得近似值
            result = (result + number / result) / 2;
        }
        return result;
    }
    
}