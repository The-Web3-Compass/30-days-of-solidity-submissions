// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SaveMyName{
     
  string name;
  string bio;
  uint256 age;

  function add (string memory _name, string memory _bio, uint256 _age )public {
    name = _name;
    bio = _bio;
    age = _age;
  }

  function retrieve() public view returns(string memory, string memory, uint256){
    return (name,bio,age);
  }

}


