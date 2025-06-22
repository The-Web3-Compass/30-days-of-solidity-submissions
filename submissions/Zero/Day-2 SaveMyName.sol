// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SaveMyName{

    string name;
    string bio;
    string location;

    function add(string memory _name, string memory _bio, string memory _location) public{ 
        name = _name;
        bio = _bio;
        location= _location;
    }

    function retrieve() public view returns (string memory, string memory, string memory){
        return(name, bio, location);
    }
}
