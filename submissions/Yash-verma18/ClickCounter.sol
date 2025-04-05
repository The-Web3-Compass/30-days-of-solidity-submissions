// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint256 public count;

    function increment() public returns (uint256) {
        count += 1;
        return count;
    }

    function decrment() public returns(uint256) {
        count -= 1;
        return count;
    }
}