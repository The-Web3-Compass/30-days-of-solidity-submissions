// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ClickCounter {

    uint256 public counter = 0;

    function click() public {
        counter += 1;
    }

    function reset() public {
        counter = 0;
    }
}git push origin main
