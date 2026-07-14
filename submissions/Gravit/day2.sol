//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract sayMyName{
    string name;
    string bio;

    function setName(string memory _name,string memory _bio) public {
        name  = _name;
        bio = _bio;
    }

    function getData() public view returns (string memory,string memory){
        return (name,bio);
    }
}