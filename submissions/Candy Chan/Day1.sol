// SPDX-License-Identifier:MIT
// use MIT permission

pragma solidity ^0.8.0;
// define solidity version
// notice: end with ;

// start code part
contract ClickCounter {

     //this is a ClickCounter（save click qty） contract

    uint256 public counter;
    // define a variable “counter” and everone can use
    //notice: unit -> uint, end with ;
    //uint256 define positive number and a≥0, or int、bool、address、string
    //public：everyone can use, or private/internal/external

    // define function/action
    function click() public {
        //this is a click function and everyone can see it

        //action is add 1 in everytime:counter=counter+1/a=a+1
        counter++;
        
    }
   

}

