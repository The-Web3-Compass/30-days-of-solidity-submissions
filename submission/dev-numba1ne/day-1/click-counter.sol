// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint256 public counter;
    
    // Increment function (existing)
    function click() public {
        counter++;
    }
    
    // New decrement function
    function decrement() public {
        require(counter > 0, "Counter cannot be negative");
        counter--;
    }
    
    // New reset function
    function reset() public {
        counter = 0;
    }
}
