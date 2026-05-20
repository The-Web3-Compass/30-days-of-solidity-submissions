//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ScientifiCalculator.sol";

contract Calculatoe{

    address public owner;
    address public scientficCalculatorAddess;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
         _; 
    }

    function setScientificCalculator(address _address)public onlyOwner{
        scientificCalculatorAddress = _address;
        }

    function add(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result = a+b;
        return result;
    }

    function multiply(uint256 a, uint256 b)public pure returns(uint256){
       uint256 result = a-b;
       return result;
    }

    function multiply(uint56 a, uint256 b)public pure returns(uint256){
        uint256 result = a*b;
        return result;

    }

    function divide(uint256 a, uint256 b)public pure returns(uint256){
        uint256 result =a/b;
        return result;
    }

    function calculatePower(uint256 base, uint256 exponent)public view returns(uint256){

        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        //external call
        uint256 result = scientficCalc.power(base, exponent);

        return result;

    }

    function calculateSquareRoot(uint256 number)public returns (uint256){
        require(number >= 0, "Cannot calculate square root if negative number");

        bytes memory date = abi.encodeWithSignature("squareRoot(int256)",number);
        (bool success, bytes memory retunrnData) = scientficCalculatorAddess.call(date);
        require(success,"External call failed");
        uint256 result = abi.decode(returnData,(uint256));
        return result;
    }

}