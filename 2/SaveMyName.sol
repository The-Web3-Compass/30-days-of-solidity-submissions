// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    string public name;   // stores the user's name
    string public bio;    // stores a short bio
    bool public hasProfile; // tracks if profile exists

    // Function to save name + bio
    function saveProfile(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
        hasProfile = true;
    }

    // Function to retrieve profile (optional since vars are public)
    function getProfile() public view returns (string memory, string memory, bool) {
        return (name, bio, hasProfile);
    }
}
