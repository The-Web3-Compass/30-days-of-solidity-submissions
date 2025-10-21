// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    //
    uint256 public counter;

    //
    function click() public {
        counter ++;
    }
    
    function reset() public {
        counter = 0;
    }

    function decrease() public {
       // if (counter > 1) {
       //     counter --;
       // }
        require(counter > 0, "Counter must be greater than 0");
        counter --;
    }
    
}