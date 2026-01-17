// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract counter {
    uint256 public number;

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function increment() public {
        number++;
    }

    function decrement() public {
        number--;
    }
}
