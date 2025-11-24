// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "./scientificCaculator.sol";

contract Caculator{
    address public owner;
    address public scientificCaculatorAddress;

    constructor(){
        owner=msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can do this action");
        _;

    }

    function setscientificCaculatorAddress(address _address) public onlyOwner{
        scientificCaculatorAddress=_address;
    }
   
   function add(uint a, uint256 b) public pure returns(uint256){
        uint256 result= a + b;
        return result;

   }

   function subtract(uint a, uint256 b) public pure returns(uint256){
        uint256 result= a - b;
        return result;

   }

   function multiply(uint a, uint256 b) public pure returns(uint256){
        uint256 result= a * b;
        return result;

   }

   function divide(uint a, uint256 b) public pure returns(uint256){
        require(b!=0, "Cannot divide by 0");
        uint256 result= a / b;
        return result;

   }

   function caculatorPower(uint256 base, uint256 exponent) public view returns(uint256){
       
       //这一行代码是将以太坊地址转换为一个可用的合约对象
       Scientific sciCal = Scientific (scientificCaculatorAddress); 
       uint256 result = sciCal.Power(base, exponent);
       return result;

   }
   
   function calculateSquareRoot(uint256 number)public returns (uint256){
        require(number >= 0 , "Cannot calculate square root of negative nmber");
     //abi.encodeWithSignature 是一种低层级的调用方式，适用于你不知道对方具体接口，只知道函数签名时。
     
     //将函数签名 squareRoot(int256) 和传入的参数 number 编码成 EVM 可以识别的 调用数据（calldata）
     //好难理解 先放一下
    
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        (bool success, bytes memory returnData) = scientificCaculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
   



   




}


