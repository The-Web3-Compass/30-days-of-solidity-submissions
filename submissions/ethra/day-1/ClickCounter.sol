// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract ClickCounter {

    uint256 public counter;

    function click() public {
        counter += 1;
    }
}