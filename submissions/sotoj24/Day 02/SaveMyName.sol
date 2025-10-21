// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    
    struct Profile {
        string name;
        string bio;
    }

    mapping(address => Profile) private profiles;


    function saveProfile(string calldata _name, string calldata _bio) external {
        profiles[msg.sender] = Profile(_name, _bio);
    }

    function getMyProfile() external view returns (string memory name, string memory bio) {
        Profile storage profile = profiles[msg.sender];
        return (profile.name, profile.bio);
    }

  
    function getProfile(address user) external view returns (string memory name, string memory bio) {
        Profile storage profile = profiles[user];
        return (profile.name, profile.bio);
    }
}
