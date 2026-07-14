// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title SaveMyName
 * @dev The task is to build a basic profile. Each user can create their profile
 * and then they can save and retrieve the information.
 */

contract SaveMyName {

    /* Defined the struct to store the user details */
    struct UserProfile {
        string name;
        string bio;
        bool status;
    }

    mapping(address => UserProfile) private profiles;

    // Save User Profile
    function saveProfile(string calldata _name, string calldata _bio) external {
        profiles[msg.sender] = UserProfile({
            name: _name,
            bio: _bio,
            status: true
        })
    }

    // Retrieve Profile
    function getMyProfile() external view returns (string memory name, string memory bio) {
        UserProfile storage profile = profiles[msg.sender];
        require(profile.exists, "Profile not found.");
        return (profile.name, profile.bio);
    }

    // Get another user's profile
    function getProfile(address user) external view returns (string memory name, string memory bio) {
        UserProfile storage profile = profiles[user];
        require(profile.exists, "Profile not found.");
        return (profile.name, profile.bio);
    }

}