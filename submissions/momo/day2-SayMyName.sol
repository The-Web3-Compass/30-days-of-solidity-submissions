// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SayMyName {
  string name;
  string bio;
  uint256 age;

  function addName(string memory _name, string memory _bio, uint256 memory _age) {
    name = _name;
    bio = _bio;
    age = _age;
  }

  function retrieve() public view returns(string memory, string memory,uint256 memory){
    return(name, bio, age);
  }

  function saveAndRetrieve(string memory _name, string _bio) public returns(string memory, string memory,uint256 memory){
    name = _name;
    bio = _bio;
    age = _age;
    return(name, bio, age);
  }
}
