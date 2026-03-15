// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./scientificCalculator.sol";
import "./statistics.sol";

contract Calculator {
    address public owner;
    address public scientificCalculatorAddress;
    address public statisticsAddress;

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

    function setStatistics(address _address) public onlyOwner {
        statisticsAddress = _address;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b;
    }

    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }

    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Cannot divide by zero");
        return a / b;
    }
     //SCIENTIFIC CALCULATOR
    // INTERFACE CALL
    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        return scientificCalc.power(base, exponent);
    }

    // LOW-LEVEL CALL
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");
        return abi.decode(returnData, (uint256));
    }

    //STATISTICS
    //INTERFACE CALL
    function calculateMean(uint256[] memory numbers) public view returns(uint256) {
        Statistics statisticsCalc = Statistics(statisticsAddress);
        return statisticsCalc.mean(numbers);
    }

    function calculateRange(uint256[] memory numbers) public view returns(uint256){
        Statistics statisticsCalc = Statistics(statisticsAddress);
        return statisticsCalc.range(numbers);
    }


    //LOW-LEVEL CALL
    function calculateMode(uint256[] memory numbers) public returns(uint256){
        bytes memory data =abi.encodeWithSignature("mode(uint256[])", numbers);
        (bool success, bytes memory returnData) = statisticsAddress.call(data);
        require(success, "External call failed");
        return  abi.decode(returnData, (uint256));
    }

    function calculateVariance(uint256[] memory numbers) public returns(uint256){
        bytes memory data = abi.encodeWithSignature("variance(uint256[])", numbers);
        (bool success, bytes memory returnData) = statisticsAddress.call(data);
        require(success, "Eternal call failed");
        return abi.decode(returnData, (uint256));
     }
}

