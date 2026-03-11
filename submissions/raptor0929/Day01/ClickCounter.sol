// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ClickCounter {
    uint256 public number;

    function click() external {
        number+=1;
    }

    function increment() external {
        number+=1;
    }

    function decrement() external {
        number-=1;
    }
}
