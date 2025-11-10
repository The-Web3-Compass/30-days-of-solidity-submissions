//SDPX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract ClickCounter {
    uint256 public counter;

    function click() public {
        counter++;
    }
}