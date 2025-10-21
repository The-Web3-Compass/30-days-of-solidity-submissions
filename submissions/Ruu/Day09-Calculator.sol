//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator{

    address public Owner;
    address public ScientificCalculatorAddress;

    constructor(){
        Owner = msg.sender;

    }

    modifier OnlyOwner(){
        require(msg.sender == Owner, "Only owner can do this action");
        _;

    }

    function SetScientificCalculator(address _address_) public OnlyOwner{
        ScientificCalculatorAddress = _address_;
        
    }

    function Add(uint256 a, uint256 b) public pure returns(uint256){
        uint256 result = a + b;
        return result;

    }

    function Subtract(uint256 a, uint256 b) public pure returns(uint256){
        uint256 result = a - b;
        return result;

    }

    function Multiply(uint256 a, uint256 b) public pure returns(uint256){
        uint256 result = a * b;
        return result;
        
    }

    function Divide(uint256 a, uint256 b) public pure returns(uint256){
        require(b != 0, "Cannot divide by 0");
        uint256 result = a / b;
        return result;
        
    }

    function CalculatePower(uint256 base, uint256 exponent) public view returns(uint256){
        ScientificCalculator ScientificCalc = ScientificCalculator(ScientificCalculatorAddress);
        uint256 result = ScientificCalc.Power(base, exponent);
        return result;

    }

    function CalculateSquareRoot(uint256 number) public returns(uint256){
        require(number >= 0, "Cannot calculate square root of negative number");
        bytes memory data = abi.encodeWithSignature("SquareRoot(int256)", number);
        (bool success, bytes memory returnData) = ScientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;

    }

}
