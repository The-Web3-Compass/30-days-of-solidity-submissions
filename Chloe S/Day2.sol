// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName{
    
string public name;
string public bio;
uint256 public age;
string public career;

    //add name&bio&age&career
    function add(string memory _name, string memory _bio, uint256 _age, string memory _career) public{
        name = _name;
        bio = _bio;
        age = _age;
        career = _career;
    }

    //retrieve name&bio&age&career
    function retrieve() public view returns ( string memory, string memory, uint256 age, string memory career){
        return (name, bio, age, career);
    }
}