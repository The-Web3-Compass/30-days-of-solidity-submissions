// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    struct Profile {
        string name;
        string bio;
        bool isActive;
    }

    mapping(address => Profile) public profiles;

    function add(string memory _name, string memory _bio) public {
        require(bytes(_bio).length <= 280, "Bio too long");
        profiles[msg.sender] = Profile(_name, _bio, true);
    }

    function retrieve()
        public
        view
        returns (string memory, string memory, bool)
    {
        Profile memory userProfile = profiles[msg.sender];
        return (userProfile.name, userProfile.bio, userProfile.isActive);
    }
}
