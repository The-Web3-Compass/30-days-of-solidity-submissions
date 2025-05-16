pragma solidity ^0.8.0;

contract SaveMyName{
  struct user{
    string name;
    string bio;
  }  

  mapping(address => user) public users;

  function addUser(string memory _name, string memory _bio) public {
    users[msg.sender].name = _name;
    users[msg.sender].bio = _bio;
  }
}
