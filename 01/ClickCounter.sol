// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint public count;

    function click() public {
        count += 1;
    }

    function decrement() public {
        require(count > 0, "Counter is zero");
        count -= 1;
    }
}