// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ScientificCalculator {
//编写计算幂的函数
function power(uint256 base, uint256 exponent) public pure returns (uint256) {
   if (exponent == 0) return 1;
else return (base ** exponent)
}

function sqareRoot(uint256 number) public pure returns (uint256){
    require(number >= 0, "Cannot calculate sqare root of negative number");
    if (number == 0) return 0;
    uint256 result = number / 2;
    for (uint256 i = 0; i < 10; i++){
        result = (result + number / result) / 2;
    }
    return result;
}

contract Calculator{
    address public owner;
    address public scientificCalculatorAddress;
    constructor() {//定义owner
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can per perform this action");
        _;
    }
    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;
    }
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a + b;
        return result;
    }
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a - b;
        return result;
    }
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 result = a* b;
        return result;
    }
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        uint256 result = a / b;
        return result;
    }
    //现在事情变得真正有趣了——我们将让一个智能合约  与另一个合约通信 。
}

function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
    ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);//地址转换
    uint256 result = scientificCalc.power(base, exponent);//调用函数
    return result;
}

function calculateSqareRoot(uint256 number) public returns (uint256) {
    require(numer >= 0, "Cannot calculate square root of negative number");//输入验证
    bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);//编码函数调用,ABI 代表应用程序二进制接口 。你可以把它看作是合同的"通信协议"——它定义了当一方合同调用另一方时数据必须如何结构化。
    (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
    require(success, "External call failed");
    uint256 result = abi.decode(returnData, (uint256));//解码响应
    return result;
}

}