// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract ClickCounter {
 uint256 public counter;

function click() public {
   counter++;
}
function click2() public {
    counter --;
}
function reset() public {
    counter =0;
}
}