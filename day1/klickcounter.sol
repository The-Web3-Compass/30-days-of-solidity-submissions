// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    // var to store clicks
    uint public count = 0;

    // fn increase the count by 1
    function click() public {
        count += 1;
    }

    // fn to decrease the count by 1
    function undo() public {
        require(count > 0, "Counter cannot go below zero");
        count -= 1;
    }

    // fn to view the current count
    function getCount() public view returns (uint) {
        return count;
    }
}
