// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter{
    //合约内容在这里

   uint256 public counter;

   function click() public {
    counter++;
   }
}

