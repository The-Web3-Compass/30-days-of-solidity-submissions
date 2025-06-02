//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Clickcounter{
    
    uint256 public counter;
    function click() public {
      counter++;
    }
      
}
