// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.26;

 contract SaveName{

    string  public    name;
    string public   bio;

    function Adder( string memory _name , string memory _bio ) public   {
        
    }

    function Retrive ( ) public  view  returns  (string memory , string memory) {
        return (name ,bio);
    }
 } 