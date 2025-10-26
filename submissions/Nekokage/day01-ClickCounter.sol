// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

contract SimpleCounter {
    // Decalring a vairaibles
    uint256 public number;

    //Declaring a function

    function click () public {
        number ++;
    }
}