// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ClickCounter {

    uint256 public counter = block.number;

    function getCounter() public view returns (uint) {
        return block.number - counter;
    }

    function click() public {
        counter++;
    }

    function unclick() public {
        counter--;
    }
}