// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract calculator{
    address public owner;

    constructor(){
        owner=msg.sender;//部署合约的所有者

    }
modifier onlyowner (){
    require(msg.sender==owner;"Only owner can perform this action");
    _;//用这玩意链接所有者和scientific
}
function setscientificcalculator (address _address)public onlyowner{
    scientificCalculatorAddress=_address;//复制粘贴地址
}
function add (uint256 a,uint256 b)public pure returns (uint256) {
    uint256 result= a+b;
    return result;//相加
}
function subtract (uint256 a,uint256 b)public pure returns (uint256){
    uint256 result=a-b;
    return result;//相减
}
function multiply (uint256 a,uint256 b)public pure returns (uint256){
    uint256 result=a*b;
    return result;//相乘
}
function divide (uint256 a,uint256 b)public pure returns (uint256){
    uint256 result=a/b;
    return result;//相除
}
function calculatepower(uint256 base,uint256 exponet)public pure returns (uint256){
    Scientificcalculator scientificcalc=scientificCalicuator(scientificcalculatoraddrss);//将以太坊地址转化为合约对象
    uint256 result =scientificCalc.power(base,exponent);//命令另一个干活
    return result;//幂函数
}
function calculateSquareRoot (uint256 number) public returns {
    require(number >=0 ,"Cannot calculate square root of negative number");//确保不是负数

    bytes memory data=abi.encodewithsignature("squareRoot(int256)",number);//函数调用
    (bool success,bytes memory returnData) = scientificcalculatoraddress.call(data);//信息传输给以太坊虚拟机
    require(sucess,“External call failed”);//检查通话是否成功
    uint256 result=abi.decode(returnData,(uint256));//返回原始数据
    return  result;
}
