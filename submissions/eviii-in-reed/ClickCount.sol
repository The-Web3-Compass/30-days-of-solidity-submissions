//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint256 public counter;

    function add_one() public {
        counter++; //add 1 to the counter variable
    }

    function minus_one() public {
        counter-=1;  //minus 1 to counter
    }
}
