//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ScientificCalculator.sol";

contract Calculator{
    address public owner;
    address public ScientificCalculatorAddress;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can do this action");
        _;
    }

    function setScientificCalcultor(address _address) public onlyOwner{
        ScientificCalculatorAddress = _address;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256){
        uint256 result = a+b;
        return result;
    }

    function subtract(uint256 a, uint256 b) public pure returns (uint256){
        uint256 result = a-b;
        return result;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256){
        uint256 result = a*b;
        return result;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256){
        uint256 result = a/b;
        return result;
    }

    function calculatorPower(uint256 base, uint256 exponent)public view returns (uint256){
    
        require(ScientificCalculatorAddress != address(0), "ScientificCalculator not set");
    
        ScientificCalculator scientificCalc = ScientificCalculator(ScientificCalculatorAddress);

        // 外部调用
        uint256 result = scientificCalc.power(base, exponent);

        return result;

    }

    // 低级调用
    function calculatorRoot(uint256 number)public returns (uint256){
        require(ScientificCalculatorAddress != address(0), "ScientificCalculator not set");

        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        (bool success,bytes memory returnData) = ScientificCalculatorAddress.call(data);
        require(success, "External call failed");
        unit256 result = abi.decode(returnData, (uint256));
        return result;

    }

}