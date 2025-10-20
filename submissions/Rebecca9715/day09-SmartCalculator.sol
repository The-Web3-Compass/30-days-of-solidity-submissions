//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// 这个里面是高级科学计算
import "./day09-ScientificCalculator.sol";

// 这个里面是基础计算
contract Calculator{

    address public owner;
    address public scientificCalculatorAddress;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
         _; 
    }

    // 设置科学计算器账户
    function setScientificCalculator(address _address)public onlyOwner{
        scientificCalculatorAddress = _address;
    }

    // 以下为基础计算
    function add(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a+b;
        return result;
    }

    function subtract(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a-b;
        return result;
    }

    function multiply(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a*b;
        return result;
    }

    function divide(uint256 a, uint256 b)public pure returns(uint256){
        require(b!= 0, "Cannot divide by zero");
        uint256 result = a/b;
        return result;
    }

    function calculatePower(uint256 base, uint256 exponent) public view returns(uint256){

        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);

        //external call 
        uint256 result = scientificCalc.power(base, exponent);

        return result;

    }

    function calculateSquareRootDirect(int256 number) public view returns (int256){
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);

        //external call 
        int256 result = scientificCalc.squareRoot(number);

        return result;
    }

    function calculateSquareRoot(uint256 number) public returns (uint256){
        require(number >= 0 , "Cannot calculate square root of negative nmber");
        // 另一种方法：函数调用，squareRoot为函数名称，并且引入number
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        // 把data的数值传给另外一个函数的address
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
}

// Day09
// 1. 两个函数都部署，在ScientificCalculator.sol上复制一下地址，粘贴进主函数的地址中
// 2. 其他可以直接计算，其中squareRoot由于data被迁移到另外一个合约的地址，无法使用view声明，因此在结果上会显示在监听端
// 3. 我增加了一个函数为calculateSquareRootDirect，使用了和power相同的方法，也可以实现，并且可以使用view