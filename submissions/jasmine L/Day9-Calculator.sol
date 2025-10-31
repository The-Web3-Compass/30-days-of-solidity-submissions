// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day9-ScientificCalculator.sol";
// 导入的是本文件夹中的合约

contract Calculator{
   address public owner;
   address public ScientificCalculatorAddress; 

   constructor (){
    owner = msg.sender;
   }

   modifier OnlyOwner(){
    require(msg.sender == owner, "No persisson!");
    _;
   }
   function SetScientificCalculator(address _address) OnlyOwner public {
    ScientificCalculatorAddress = _address;
   }
    // 加法
   function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a+b;
    }
    // 减法
    function sub(int256 a, int256 b) public pure returns(int256){
        return a-b;
    }
    // 关于无符号整数的除法，暂时不考虑溢出的问题
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {     
        return a*b;
    }
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Invaild divide number!");
        return a/b;
    }

    function calculatePower(uint256 x, uint256 n) public view returns (uint256) {
        ScientificCalculator scientificCalculator = ScientificCalculator(ScientificCalculatorAddress);
        uint256 result = scientificCalculator.power(x,n);
        return result;
    }
    function calculateSquare(uint256 number) public view returns(uint256){
        ScientificCalculator scientificCalculator = ScientificCalculator(ScientificCalculatorAddress);
        uint256 result = scientificCalculator.square(number);
        return result;
    }
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        require(number >= 0, "Number must > 0 ");
        bytes memory data = abi.encodeWithSignature("square(uint256)", number);
        
        (bool success, bytes memory returnData) = ScientificCalculatorAddress.call(data);
        
        require(success, "Invaild call!");

        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
}   


