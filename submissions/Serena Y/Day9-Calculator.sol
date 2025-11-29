// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import"./Day9-ScientificCalculator.sol";//调用科学计算器

contract Calculator{
    address public owner;
    address public scientificCalculatorAddress;
    constructor(){
        owner=msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner{
        scientificCalculatorAddress=_address;
    }

    function add(uint256 a, uint256 b) public pure returns(uint256){
        uint256 results=a+b;
        return results;
    }

    function subtract(uint256 a, uint256 b) public pure returns(uint256){
        uint256 results=a-b;
        return results;
    }

    function multiply(uint256 a, uint256 b) public pure returns(uint256){
        uint256 results=a*b;
        return results;
    }

    function divide(uint256 a, uint256 b) public pure returns(uint256){
        uint256 results=a/b;
        return results;
    }


    function calculatePower(uint256 base, uint256 exponent)public returns (uint256){
        

        bytes memory data = abi.encodeWithSignature("power(uint256,uint256)",base,exponent);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }



    function calculateSquareRoot(uint256 number)public returns (uint256){
        require(number >= 0 , "Cannot calculate square root of negative nmber");

        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }


}