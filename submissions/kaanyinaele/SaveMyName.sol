// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserProfile {
    string public name;
    bool public isActive;

    // Function to set user profile
    function setProfile(string memory _name, bool _isActive) public {
        name = _name;
        isActive = _isActive;
    }

    // Function to get user profile
    function getProfile() public view returns (string memory, bool) {
        return (name, isActive);
    }
}
