// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract savemyname{
string name;
string location;
uint256 age;
string bio;
function add (string memory _name,string memory _location,string memory _bio) public {
    name = _name;
    location = _location;
    bio = _bio;
}
function setage(uint256 _age) public {
    age= _age;
}
function retrieve() public view returns (string memory, string memory,uint256, string memory){
    return (name, location, age, bio);
}
}