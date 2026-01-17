// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScientificCalculator.sol";

contract Calculator {
    address public owner;
    address public scAddress;

    ScientificCalculator public sc;

    constructor (address _scAddress) {
        owner = msg.sender;
        sc = ScientificCalculator(_scAddress);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
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
        require (b != 0, "Can't divide a number by 0.");
        return a / b;
    }

    function power(uint256 base, uint256 exp) public view returns (uint256) {
        return sc.power(base, exp);
    }

    function squareRoot(uint256 a) public view returns (uint256) {
        return sc.squareRoot(a);
    }


}