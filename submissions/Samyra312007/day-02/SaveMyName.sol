//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

contract SaveName{
    string name;
    string bio;

    function save(string memory _name, string memory _bio) public{
        name = _name;
        bio = _bio;
    }

    function retrieve() public view returns (string memory, string memory){
        return (name, bio);
    }
}