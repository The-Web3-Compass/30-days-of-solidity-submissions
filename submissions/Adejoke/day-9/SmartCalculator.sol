// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// File 1: ScientificCalculator.sol
contract ScientificCalculator {
    function power(
        uint256 base,
        uint256 exponent
    ) public pure returns (uint256) {
        if (exponent == 0) return 1;
        else return (base ** exponent);
    }

    function squareRoot(uint256 number) public pure returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        if (number == 0) return 0;

        uint256 result = number / 2;
        for (uint256 i = 0; i < 10; i++) {
            result = (result + number / result) / 2;
        }
        return result;
    }
}

// File 2: Calculator.sol
contract Calculator {
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

    // INTERFACE CALL
    function calculatePower(
        uint256 base,
        uint256 exponent
    ) public view returns (uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(
            scientificCalculatorAddress
        );
        return scientificCalc.power(base, exponent);
    }

    // LOW-LEVEL CALL
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        bytes memory data = abi.encodeWithSignature(
            "squareRoot(uint256)",
            number
        );
        (bool success, bytes memory returnData) = scientificCalculatorAddress
            .call(data);
        require(success, "External call failed");
        return abi.decode(returnData, (uint256));
    }
}
