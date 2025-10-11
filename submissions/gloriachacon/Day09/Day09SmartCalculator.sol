// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Calculator {
    function add(uint256 a, uint256 b) external pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) external pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) external pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) external pure returns (uint256) { require(b != 0); return a / b; }
}

contract SmartCalculator {
    address public owner;
    address public calculator;

    constructor(address _calculator) {
        owner = msg.sender;
        calculator = _calculator;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setCalculator(address _calculator) external onlyOwner {
        require(_calculator != address(0), "Invalid");
        calculator = _calculator;
    }

    function add(uint256 a, uint256 b) external view returns (uint256) {
        return Calculator(calculator).add(a, b);
    }

    function sub(uint256 a, uint256 b) external view returns (uint256) {
        return Calculator(calculator).sub(a, b);
    }

    function mul(uint256 a, uint256 b) external view returns (uint256) {
        return Calculator(calculator).mul(a, b);
    }

    function div(uint256 a, uint256 b) external view returns (uint256) {
        return Calculator(calculator).div(a, b);
    }
}