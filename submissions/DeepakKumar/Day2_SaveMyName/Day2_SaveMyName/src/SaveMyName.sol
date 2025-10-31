// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SaveMyName {
    // Structure to store user data
    struct Profile {
        string name;
        string bio;
    }

    // Mapping to store each user's profile
    mapping(address => Profile) private profiles;

    // Event for logging profile updates
    event ProfileUpdated(address indexed user, string name, string bio);

    // Function to save user name and bio
    function saveMyProfile(string memory _name, string memory _bio) public {
        profiles[msg.sender] = Profile(_name, _bio);
        emit ProfileUpdated(msg.sender, _name, _bio);
    }

    // Function to get user profile
    function getMyProfile() public view returns (string memory, string memory) {
        Profile memory profile = profiles[msg.sender];
        return (profile.name, profile.bio);
    }

    // Optional: function to get any user's profile (for admin use or open view)
    function getUserProfile(address _user) public view returns (string memory, string memory) {
        Profile memory profile = profiles[_user];
        return (profile.name, profile.bio);
    }
}
