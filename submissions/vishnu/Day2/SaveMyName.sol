// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SaveMyName{
    struct Profile{
        string name;
        string bio;
    }

    mapping(address => Profile) private profiles;

    function setProfile(string calldata _name, string calldata _bio) external {
        profiles[msg.sender] = Profile({
            name: _name,
            bio: _bio
        });
    }

    function getMyName() external view returns (string memory, string memory) {
        Profile storage profile = profiles[msg.sender];
        return (profile.name, profile.bio);
    }
}
