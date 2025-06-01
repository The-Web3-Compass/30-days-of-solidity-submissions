// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract ClickCounter{
    uint256 private count;

    function increment() public {
        count++;
    }

    function getCount() external view returns(uint){
        return count;
    }
}