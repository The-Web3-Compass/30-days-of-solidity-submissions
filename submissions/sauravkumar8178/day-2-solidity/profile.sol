// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnhancedProfile {
    struct Profile {
        string username;
        string bio;
        uint256 age;
        string location;
        string profilePic;  // could store IPFS hash or URL
        uint256 joinedOn;
    }

    // Mapping from user address to profile
    mapping(address => Profile) private profiles;

    // Event for profile creation/update
    event ProfileUpdated(
        address indexed user,
        string username,
        string bio,
        uint256 age,
        string location,
        string profilePic
    );

    // Set or update profile
    function setProfile(
        string memory _username,
        string memory _bio,
        uint256 _age,
        string memory _location,
        string memory _profilePic
    ) public {
        profiles[msg.sender] = Profile({
            username: _username,
            bio: _bio,
            age: _age,
            location: _location,
            profilePic: _profilePic,
            joinedOn: block.timestamp
        });

        emit ProfileUpdated(msg.sender, _username, _bio, _age, _location, _profilePic);
    }

    // Get profile by address
    function getProfile(address _user)
        public
        view
        returns (
            string memory username,
            string memory bio,
            uint256 age,
            string memory location,
            string memory profilePic,
            uint256 joinedOn
        )
    {
        Profile memory profile = profiles[_user];
        return (
            profile.username,
            profile.bio,
            profile.age,
            profile.location,
            profile.profilePic,
            profile.joinedOn
        );
    }
}
