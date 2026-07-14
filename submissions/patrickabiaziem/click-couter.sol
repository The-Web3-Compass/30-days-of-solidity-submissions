// SPDX-License-Identifier:MIT
pragma solidity ^0.8.26;

contract Counter {
    uint256 public counter;

    function increment(uint256 input) public pure returns (uint256) {
        return input + 1;
    }
    function decrement(uint256 input) public pure returns (uint256) {
       return input -1;
    
    }

    
}
