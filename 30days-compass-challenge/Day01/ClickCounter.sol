// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract counterClick {

  uint256 public counter == 0;

  function click() public {
    counter = counter + 1;
  }

  function restart() public {
    counter = 0;
  }
}