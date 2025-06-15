// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract clickcounter {

    uint256 public counter;

    function click() public {
        counter++;
    }

    function reset() public {
        counter = 0;
    }
}
