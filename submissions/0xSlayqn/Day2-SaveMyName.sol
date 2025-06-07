// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SaveMyName {

    string public Name;
     string public  Bio;

    function saveInfo(string memory _name, string memory _bio) public {
        Name = _name;
        Bio = _bio;
    }

    function retrieveInfo() public view returns(string memory, string memory) {
        return (Name,Bio);
    }
}
