// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./scientificCalc.sol";

contract SmartCalculator {
    address public owner;
    address public scientificCalcAddress;

    event ScientificCalcAddressUpdated(address indexed newAddress);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner!");
        _;
    }

    function setScientificCalcAddress(address _address) public onlyOwner {
        scientificCalcAddress = _address;
        emit ScientificCalcAddressUpdated(_address);
    }

    function addTwoNumbers(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function subTwoNumbers(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b;
    }

    function mulTwoNumbers(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }

    function divTwoNumbers(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "Divisor must not be zero!");
        return a / b;
    }

    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalcAddress);
        return scientificCalc.power(base, exponent);
    }

    function calculateSquareRoot(uint256 number) public returns (uint256) {
        require(number >= 0, "Number must be non-negative!");

        bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", number);
        (bool success, bytes memory returnData) = scientificCalcAddress.call(data);
        require(success, "Call to ScientificCalculator failed!");

        return abi.decode(returnData, (uint256));
    }
}