// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

contract SaveMyName {

    string public myName;
    string public myBio;

    constructor() { }

    function setProfile(string memory name, string memory bio) public {
        myName = name;
        myBio = bio;
    }

    function getProfile() public view returns (string memory, string memory) {
        return (myName, myBio);
    }
}