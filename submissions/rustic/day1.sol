//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract NumberCount {
    uint256 public number;

    function incrementCount() public {
        number++;
    }

    function decrementCount() public {
        number--;
    }
}