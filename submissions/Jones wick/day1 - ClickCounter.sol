// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ClickCounter {
    uint256 public counter;

    function Increment() public {
        counter++;
    }
    function Decrement () public {
        if(counter>0)
            counter--;
    }
    function Reset () public {
        counter=0;
    }    
}
