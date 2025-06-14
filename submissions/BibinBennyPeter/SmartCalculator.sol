// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ICalculator {
    function add(uint256 a, uint256 b) external pure returns (uint256);
    function subtract(uint256 a, uint256 b) external pure returns (uint256);
    function multiply(uint256 a, uint256 b) external pure returns (uint256);
    function divide(uint256 a, uint256 b) external pure returns (uint256);
}

contract Calcluator {
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
        require(b != 0, "Division by zero");
        return a / b;
    }
}

contract SmartCalculator {
    

  address public calculatorAddress;

  constructor (address _calculatorAddress) public {
    calculatorAddress = _calculatorAddress;
  }
  function add(uint256 a, uint256 b) public view returns (uint256) {
        return ICalculator(calculatorAddress).add(a, b);
    }

    function subtract(uint256 a, uint256 b) public view returns (uint256) {
        return ICalculator(calculatorAddress).subtract(a, b);
    }

    function multiply(uint256 a, uint256 b) public view returns (uint256) {
        return ICalculator(calculatorAddress).multiply(a, b);
    }

    function divide(uint256 a, uint256 b) public view returns (uint256) {
        return ICalculator(calculatorAddress).divide(a, b);
    }
  
}
