// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

/**
 * @title ClickCounter
 * @dev The task is to build a digital clicker. Each click increases the
 * count of the variable (here, `count`) by one. The variable is a number (a `uint`)
 */
contract ClickCounter {
    uint256 public count = 0;

    function click() public {
        count += 1;
    }
}