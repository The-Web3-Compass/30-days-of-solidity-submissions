// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SaveMyName{

    string name;
    string bio;

    function add(string memory _name, string memory _bio) public{
        name = _name;
        bio = _bio;
    }

    function retrieve() public view returns(string memory, string memory){
        return(name, bio);
    }

    function saveAndRetrieve(string memory _name, string memory _bio) public returns(string memory, string memory){
        name = _name;
        bio = _bio;
        return (name, bio);
    }
}
