// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

contract ClickCounter {
    // Decalring a vairaibles
    uint public number;

    //Declaring a function

    function increment () public {
        number ++;
    }

    function decrement () public {
        require(number > 0, "Number must be greater than 0");
        number --;
    }

    function reset () public {
        number = 0;
    }
}