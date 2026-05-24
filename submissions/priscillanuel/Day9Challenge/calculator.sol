// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "./SmartCalculator1.sol";

contract calculator {
    // variables
    address public owner;
    address public scientificCalculatorAddress;

    //modifiers
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "you're not the owner");
        _;
    }
    // functions

    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;
    }

    function addition(uint56 a, uint256 f) public pure returns (uint256) {
        return a + f;
    }

    function subtraction(uint a, uint f) public pure returns (uint) {
        return a - f;
    }

    function multiply(uint a, uint f) public pure returns (uint) {
        return a * f;
    }

    function divide(uint a, uint f) public pure returns (uint) {
        require(f != 0, "cannot divide by zero");
        return a / f;
    }

    function mean(uint[] memory numbers) public pure returns (uint) {
        require(numbers.length > 0, "Array must not be empty");
        uint total = 0;
        for (uint256 i = 0; i < numbers.length; i++) {
            total += numbers[i];
        }

        return total / numbers.length;
    }

    function median(uint[] memory numbers) public pure returns (uint) {
        require(numbers.length > 0, "Array must not be empty");

        // Step 1: Sort the array (simple method)
        for (uint i = 0; i < numbers.length; i++) {
            for (uint j = i + 1; j < numbers.length; j++) {
                if (numbers[i] > numbers[j]) {
                    uint temp = numbers[i];
                    numbers[i] = numbers[j];
                    numbers[j] = temp;
                }
            }
        }

        uint mid = numbers.length / 2;

        // Step 2: Check if even or odd
        if (numbers.length % 2 == 0) {
            // even → average of two middle numbers
            return (numbers[mid - 1] + numbers[mid]) / 2;
        } else {
            // odd → middle number
            return numbers[mid];
        }
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
