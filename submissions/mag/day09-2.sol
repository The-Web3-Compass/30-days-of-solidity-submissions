//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./day09-1.sol";
contract Calculater {
    address public owner;
    address public scientificCalculatorAddress;

    constructor() {owner = msg.sender;
    }
    modifier onlyOwner() {
         require(msg.sender == owner, "Owner only");
         _;
    }
    function setScientificCalculatorAddress(address _address) public onlyOwner {
         scientificCalculatorAddress = _address;
    }
    function add(uint256 a, uint256 b) public pure returns (uint256) {
         uint256 result = a+ b;
         return result;
    }
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
         uint256 result = a - b;
         return result;
    }
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
         uint256 result = a * b;
         return result;
    }
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
         require(b != 0, "Division by zero");
         uint result = a / b;
         return result;
    }
    function power(uinnt256 base, uint256 exponent) public view returns (uint256) {
        scientificCalculator scientificCalc = scientificCalculator(scientificCalculatorAddress);
        uint256 result = scientificCalc.power(base, exponent);
        return result;
    } 
    function squareRoot(uint256 number) public returns (uint256) {
        requi>=0, ("Input must be non-negative");
        bytes memory data = abi.encodewithSignature("squareRoot(int256)", number);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(sucess,"External call failed");
        uint256 result = abi.decide(returnData, (uint256));
        return result;
    }
}