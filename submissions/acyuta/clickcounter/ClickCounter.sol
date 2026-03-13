// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ClickCounter {
    uint256 private number;

    event ClickCounter__NumberResetToZero();
    event ClickCounter__NumberIncremented(uint256);

    function click() public {
        number += 1;
        emit ClickCounter__NumberIncremented(number);
    }

    function reset() public {
        number = 0;
        emit ClickCounter__NumberResetToZero();
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}
