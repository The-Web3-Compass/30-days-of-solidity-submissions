//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator{

    address public owner;
    address public scientificCalculatorAddress;

    constructor() {
        owner = msg.sender;
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"only owner can do thid=s action");
        _;
    }

    function setScientficCalculator(address _address)public onlyOwner{
        scientificCalculatorAddress = _address;
    }

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
        require(b != 0,"Cannot divide by zero");
        uint256 result = a/b;
        return result;
    }

    function calculatorPower(uint256 base,uint256 exponent)public view returns(uint256){
    
    ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);

    uint256 result = scientificCalc.power(base,exponent);

    return result;

}
    function calculatorSquareRoot (uint256 number)public returns (uint256){
        require(number>= 0,"Cannot calculate square root of negative number");

        bytes memory data = abi.encodeWithSignature("squareRoot(int256)",number);
        (bool success , bytes memory returnData ) = scientificCalculatorAddress.call(data);
        require(success,"Eternal call failed");
        uint256 result = abi.decode(returnData,(uint256));
        return result;
    }

}
