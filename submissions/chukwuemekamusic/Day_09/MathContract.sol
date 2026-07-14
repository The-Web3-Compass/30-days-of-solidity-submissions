// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MathContract {
    error MathLib_DivideByZero();
  function add(uint x, uint y) public pure returns (uint z) {
    return x + y;
  }

  function sub(uint x, uint y) public pure returns (uint z) {
    return x - y;
  }

  function div(uint x, uint y) public pure returns (uint z) {
    if (y == 0) revert MathLib_DivideByZero();
    return x / y;
  }

  function mul(uint x, uint y) public pure returns (uint z) {
    if (x == 0 || y == 0) return 0;
    return x * y;
  }

  function power(uint x, uint y) public pure returns (uint z) {
    if (y == 0) return 1;
    return x ** y;
  }

  function getContractAddress() public view returns (address) {
    return address(this);
  }
}