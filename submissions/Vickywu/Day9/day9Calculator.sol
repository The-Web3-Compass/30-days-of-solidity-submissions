//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day9ScientificCalculator.sol";  //`"./"` 部分告诉 Solidity：“查看与这个文件相同的目录（或文件夹）中，找到 ScientificCalculator.sol。”

contract Calculator{

    address public owner;  //owner 将存储部署此合约的地址
    address public scientificCalculatorAddress;  //scientificCalculatorAddress 是我们存放已部署的 ScientificCalculator 地址的地方

    constructor(){
        owner = msg.sender;  //当有人部署这个合约时，他们的地址被存储为所有者 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
         _; 
    }

    function setScientificCalculator(address _address)public onlyOwner{
        scientificCalculatorAddress = _address;  //ScientificCalculator 合约部署完成，您可以将它的地址复制并粘贴到这里。这个函数会保存该地址，以便我们之后可以调用它的函数。
    }

    //加法
    function add(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a+b;
        return result;
    }

    function subtract(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a-b;
        return result;
    }

    //乘法
    function multiply(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a*b;
        return result;
    }

    //除法
    function divide(uint256 a, uint256 b)public pure returns(uint256){
        require(b!= 0, "Cannot divide by zero");  //在执行之前，它会检查 b 是否为零——只是为了避免错误
        uint256 result = a/b;
        return result;
    }

    function calculatePower(uint256 base, uint256 exponent)public view returns(uint256){
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);  //将一个普通的以太坊地址（scientificCalculatorAddress）转换成一个可用的合约对象——在这个例子中，是一个 ScientificCalculator
        uint256 result = scientificCalc.power(base, exponent);  //向部署的 ScientificCalculator 合约发送一个只读调用，要求它计算 base ** exponent
        return result;
    }

    function calculateSquareRoot(uint256 number)public returns (uint256){
        require(number >= 0 , "Cannot calculate square root of negative nmber");

        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);  //使用一种称为 ABI 的东西来准备函数调用。在使用高级函数调用（如 otherContract.someFunction()）时，Solidity 会为你处理 ABI 编码。但使用低级调用时， 你必须手动处理。- `"squareRoot(int256)"` 是完整的函数签名（名称+参数类型）。number` 是我们作为参数传递的值。结果是字节数组 (`bytes memory`)，其中包含在区块链上调用该函数所需的所有信息。
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data); //进行低级调用。- `.call(data)` 将这些数据发送到存储在 `scientificCalculatorAddress` 中的地址。它返回两件事：`success`（一个布尔值，告诉我们调用是否成功）`returnData`（一个字节数组，包含函数返回的内容）
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }

    
}