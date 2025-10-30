//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day09-ScientificCalculator.sol";

contract Calculator {
    address public owner;
    address public addScientificCal;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function setScientificCalculatorAddress(address _address) public onlyOwner {
        addScientificCal = _address;
    }

    function add(uint256 _a, uint256 _b) public pure returns(uint256) {
        return (_a + _b);
    }

    function subtract(uint256 _a, uint256 _b) public pure returns(uint256) {
        return (_a - _b);
    }

    function multiply(uint256 _a, uint256 _b) public pure returns(uint256) {
        return (_a * _b);
    }

    function divide(uint256 _a, uint256 _b) public pure returns(uint256) {
        require(_b != 0, "Cannot divide by zero");
        return (_a / _b);
    }

    function calculatePower(uint256 _base, uint256 _exponent) public returns(uint256) {
        require(address(0) != addScientificCal, "Set ScientificCalculator first");
        // ScientificCalculator scientifcCal = ScientificCalculator(addScientificCal);
        // return scientifcCal.power(_base, _exponent);

        bytes memory data = abi.encodeWithSignature("power(uint256,uint256)", _base, _exponent);
        (bool success, bytes memory returnData) = addScientificCal.call(data);

        require(success, "Externel call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }

    function calculateSquareRoot(uint256 _number) public view returns(uint256) {
        require(address(0) != addScientificCal, "Set ScientificCalculator first");
        require(_number > 0, "Only accept positive number");

        // bytes memory data = abi.encodeWithSignature("squareRoot(uint256)", _number);
        // (bool success, bytes memory returnData) = addScientificCal.call(data);

        // require(success, "Externel call failed");
        // uint256 result = abi.decode(returnData, (uint256));
        // return result;

        ScientificCalculator scientificCal = ScientificCalculator(addScientificCal);
        return scientificCal.squareRoot(_number);
    }

}