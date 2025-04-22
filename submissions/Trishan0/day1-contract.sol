// SPDX-License-Identifier: MIT
 pragma solidity >=0.4.16 <0.9.0;

contract ClickCounter {
    uint256 public counter;

    function increment() public {
        counter++;
    }

    function decrement() public {
        if (counter ==0){
            return;
        }
        counter--;
    }

    function reset() public {
        counter = 0 ;
    }
}