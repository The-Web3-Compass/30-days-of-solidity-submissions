// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SaveMyName{
    string name;
    string bio;

   function store_retrive(string memory _name, string memory _bio) public returns(string memory, string memory){
    name = _name;
    bio = _bio;
    return(name, bio);
       }
}
