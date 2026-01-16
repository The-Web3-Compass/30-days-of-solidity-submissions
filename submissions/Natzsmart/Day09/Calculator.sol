// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Import the external ScientificCalculator contract
import "./ScientificCalculator.sol";

contract Calculator {

    address public owner;  // Address of the contract owner
    address public scientificCalculatorAddress; // Address of the deployed ScientificCalculator contract

    // Constructor sets the deployer as the owner
    constructor(){
        owner = msg.sender;
    }

    // Modifier that restricts function access to the owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
        _; 
    }

    // Function to set the address of the ScientificCalculator contract
    function setScientificCalculator(address _address) public onlyOwner {
        scientificCalculatorAddress = _address;
    }

    // Adds two numbers
    function add(uint256 a, uint256 b) public pure returns(uint256) {
        uint256 result = a + b;
        return result;
    }

    // Subtracts b from a
    function subtract(uint256 a, uint256 b) public pure returns(uint256) {
        uint256 result = a - b;
        return result;
    }

    // Multiplies two numbers
    function multiply(uint256 a, uint256 b) public pure returns(uint256) {
        uint256 result = a * b;
        return result;
    }

    // Divides a by b with zero-division check
    function divide(uint256 a, uint256 b) public pure returns(uint256) {
        require(b != 0, "Cannot divide by zero");
        uint256 result = a / b;
        return result;
    }

    // Calls the power function from the external ScientificCalculator contract
    function calculatePower(uint256 base, uint256 exponent) public view returns(uint256) {
        ScientificCalculator scientificCalc = ScientificCalculator(scientificCalculatorAddress);
        
        // External call to calculate exponentiation
        uint256 result = scientificCalc.power(base, exponent);
        return result;
    }

    // Calls the squareRoot function using low-level call
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        require(number >= 0 , "Cannot calculate square root of negative number");

        // Encode the function signature and arguments for the low-level call
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        
        // Perform the low-level call to the external contract
        (bool success, bytes memory returnData) = scientificCalculatorAddress.call(data);
        require(success, "External call failed");

        // Decode the result returned from the external call
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
}