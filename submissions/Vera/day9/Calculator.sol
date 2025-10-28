// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator{
    address owner;
    address scientificCalculatorAddress;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender,"Only owner can perform this action");
        _;
    }

    function setScientificCalculatorAddress(address _scientificCalculatorAddress)public onlyOwner{
        require(_scientificCalculatorAddress != address(0),"Invalid address");
        scientificCalculatorAddress = _scientificCalculatorAddress;
    }

    function add(uint256 a,uint256 b)public pure returns (uint256){
        return (a+b);
    }

    function subtract(uint256 a,uint256 b)public pure returns (uint256){
        return (a-b);
    }

    function multiply(uint256 a,uint256 b)public pure returns (uint256){
        return (a*b);
    }

    function divide(uint256 a,uint256 b)public pure returns (uint256){
        require(b!=0,"Cannot divide by zero");
        return (a/b);
    }

    function power(uint256 base,uint256 exponent)public view returns (uint256){
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        return (scientificCalc.power(base, exponent));
    }

    function suqareRoot(uint256 number)public returns (uint256){
        require(number >= 0, "Cannot calculate square root of negative number");
        bytes memory data = abi.encodeWithSignature("suqareRoot(uint256)", number);
        (bool success,bytes memory result) = scientificCalculatorAddress.call(data);

        require(success,"External call failed");

        uint256 root = abi.decode(result, (uint256));

        return (root);
    }
}