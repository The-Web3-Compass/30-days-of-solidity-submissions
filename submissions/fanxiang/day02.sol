// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyInformation {
    string name;
    string bio;
    string age;
    string job;

    function add(string memory _name,string memory _bio,string memory _age,string memory _job) public{
        name = _name;
        bio = _bio;
        age = _age;
        job = _job;
    }
    function retrieve() public view returns (string memory,string memory,string memory,string memory){
        return (name,bio,age,job);
    }
}

