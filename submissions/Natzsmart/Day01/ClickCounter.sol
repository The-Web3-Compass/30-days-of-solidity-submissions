/*--------------------------------------------------------------------------
  File:   ClickCounter.sol
  Author: Natzsmart 
  Date:   04/01/2025
  Description:
    A simple counterclick contract to learn variable declaration, function 
    creation, and basic arithmetic.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Simple Counter Contract
contract ClickCounter {
    uint256 public counter;

   function click()public {
    counter ++;
   }
}