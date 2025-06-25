// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

// Simple contract to count the number of clicks 
contract ClickCounter {

    uint256 count;         // variable to store thre count 

    constructor() {
        count = 0;
    }
    
    // function to increment the count 
    function clickincrement (uint256 _increment) public {
        count += _increment;
    }

    // function to decrement the count 
    function clickdecrement (uint256 _decrement) public {
        count -= _decrement;
    }
    
    // function to get the total count 
    function totalcount() public view returns (uint256) {
        return count;
    }
}
