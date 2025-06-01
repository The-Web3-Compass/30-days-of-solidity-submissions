// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// Create a contract named ClickCounter.
contract ClickCounter{
    
    uint256 public counter=0;
    function click() public{ 
        counter++;      
    }
}