// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./scientificCalculator.sol";

contract calculator{
    address public owner;
    address public ScientificCalculatorAddress;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not owner");
        _;
    }

    function setScientificCalculator (address _address) public onlyOwner{
        ScientificCalculatorAddress = _address;
    }

    function add (uint256 _a, uint256 _b) public pure returns (uint256){
        return _a + _b;
    }

    function substract (uint256 _a, uint256 _b) public pure returns (uint256){
        return _a - _b;
    }

    // -------------------------------------------------
    // Calls the 'power()' function from another contract 
    // in a high-level, type-safe way
    // -------------------------------------------------
    function calculatePower(uint256 base, uint256 exponent) public view returns (uint256) {
        // 'ScientificCalculator' is the name of another contract (like a class)
        // 'scientificCalc' is just a variable name — we can call it anything we like
        // and *casts* address into a usable contract object — in this case, a ScientificCalculator.
        ScientificCalculator scientificCalc = ScientificCalculator(ScientificCalculatorAddress);
        // call function from that external contract
        uint256 result = scientificCalc.power(base, exponent);
        return result;
    }
    // -------------------------------------------------
    // Calls the 'squareRoot()' function using a low-level call
    // without importing other code file 
    // -------------------------------------------------
    function calculateSquareRoot(uint256 number) public returns (uint256) {
        require(number >= 0, "Cannot calculate square root of negative number");
        // encode full function signature (name + parameter types) 
        // + the value we're passing as an argument into bytes
        bytes memory data = abi.encodeWithSignature("squareRoot(int256)", number);
        
        // '.call(data)' sends that encoded data to the address stored in 'ScientificCalculatorAddress'
        // It returns two things:
        //   - 'success': a boolean that tells us if the call worked
        //   - 'returnData': a byte array that holds whatever the function returned
        (bool success, bytes memory returnData) = ScientificCalculatorAddress.call(data);
        require(success, "External call failed");
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }

}