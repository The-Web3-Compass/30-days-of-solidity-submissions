// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SaveMyName{

    string name;
    string bio;
    string job;
    string age;

    function add(string memory _name,string memory _bio,
    string memory _job,string memory _age) public{
        name = _name;
        bio = _bio;
        job = _job;
        age = _age; 
    }
     
    function retrieve() public view 
    returns(string memory, string memory, string memory,string memory){
        return(name,bio,job,age);
    }
}