// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Calculator {
    uint256 result;

    function add(uint256 _num1, uint256 _num2) public returns (uint256) {
        result = _num1 + _num2;
        return result;
    }

    function sub(uint256 _num1, uint256 _num2) public returns (uint256) {
        result = _num1 - _num2;
        return result;
    }

    function multiply(uint256 _num1, uint256 _num2) public returns (uint256) {
        result = _num1 * _num2;
        return result;
    }

    function divide(uint256 _num1, uint256 _num2) public returns (uint256) {
       require (_num2 != 0, "Division by zero error");
       
        result = _num1 / _num2;
        return result;
    }

    function getResult() public view returns (uint256) {
        return result;
    }

}