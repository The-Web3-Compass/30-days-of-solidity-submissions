// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
import "./Day09-ScientificCalculator.sol";


contract Calculator{

    /**
    This contract handles the basic math: adding, subtracting,
    multiplying, and dividing numbers. 
    */

    address public owner;
    address public scientificCalculatorAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;
    }

    // "pure" is a function modifier used to declare a function 
    // that neither reads nor modifiers the state variables of the contract 
    function add(uint256 a,uint256 b) public pure returns(uint256){
        return a + b;
    }

    function substract(uint256 a,uint256 b) public pure returns(uint256){
        return a - b;
    }

    function multiply(uint256 a,uint256 b) public pure returns(uint256){
        return a * b;
    }

    function device(uint256 a,uint256 b) public pure returns(uint256){
        require(b != 0,"Cannot divide by zero");
        return a / b;
    }

    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        
        return scientificCalc.power(base, exponent);

    }


    function calculateSquareRoot(uint256 number) public returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        // Application Binary Interface:
        // it defines how data must be structured when one contract calls another.
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);

        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");

        uint256 result = abi.decode(returnData, (uint256));
        return result;

    } 




}