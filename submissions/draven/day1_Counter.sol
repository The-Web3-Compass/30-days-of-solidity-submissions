// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ClickCounter {
  uint256 public counter;

  function add() public {
    counter++;
  }

  function minus() public {
    counter--;
  }

  function clear() public {
    counter = 0;
  }

}