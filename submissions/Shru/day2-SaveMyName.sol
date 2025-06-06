// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    string name;
    string bio;

    // Function to save name and bio
    function saveProfile(string memory _name, string memory _bio) external {
        name = _name;
        bio = _bio;
    }

    // Function to get name and bio
    function getProfile() external view returns (string memory, string memory) {
        return (name, bio);
    }

}
