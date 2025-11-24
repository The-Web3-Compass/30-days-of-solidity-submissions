//SPDX-License-Identifier: MIT
//MIT: free to use

pragma solidity ^0.8.0; //code  for version 0.8.0 and higher 

contract ClickCounter {
    uint256 public counter; // define a public state variable "counter" as uint256
    //　 uint: Unsigned integers, i.e. positive integers including 0
    //  256 means that it can represent numbers up to the 256th power of 2.)

    function click() public{
        counter++;
    }
}
