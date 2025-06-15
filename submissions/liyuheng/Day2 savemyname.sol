// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract savemyname{

    string name;
    string bio;

    function add(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    function retrive () public view returns (string memory, string memory){
        return (name,bio);
    }

}