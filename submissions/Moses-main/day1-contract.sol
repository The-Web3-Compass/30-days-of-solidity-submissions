// SPDX-License-Identifier: MIT
pragma solidity 0.8.2 <0.9.0;

contract ClickCounter {

    // 📖 Description:
    // A simple counter contract to learn variable declaration, 
    // function creation, and basic arithmetic.
    //  Like a YouTube view counter, tracking how many times a button is clicked.

    uint256 public count;

    // Function to get the current count
    function get() public view returns (uint256)  {
        return count;
    }

    // Funtion to increment count by 1
    function incr() public {
        count++;
    }

    // Function to decrement count by 1
    function decr() public {
        count--;
    }


}