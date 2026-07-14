// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Profile {
    string private name;
    string private bio;

    function setName(string memory _name) public {
        name = _name;
    }

    function setBio(string memory _bio) public {
        bio = _bio;
    }

    function setNameAndBio(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getBio() public view returns (string memory) {
        return bio;
    }

    function getProfile() public view returns (string memory, string memory) {
        return (name, bio);
    }
}