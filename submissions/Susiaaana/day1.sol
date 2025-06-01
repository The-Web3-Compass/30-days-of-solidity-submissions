// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint256 public counter;
    
    function Plus()  public {
        counter++;
    }

    function Minus() public {
        counter--;
    }
    
    function Reset() public {
        counter = 0;
    }

}