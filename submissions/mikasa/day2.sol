// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserProfile {
    struct Profile {
        string name;
        string bio;
        bool exists;
    }
    mapping(address => Profile) public profiles;
    address[] public userAddresses;
    event ProfileUpdated(address indexed user, string name, string bio);
    function setProfile(string memory _name, string memory _bio) public {
        address user = msg.sender;
        if (!profiles[user].exists) {
            userAddresses.push(user);
        }
        profiles[user] = Profile({
            name: _name,
            bio: _bio,
            exists: true
        });
        emit ProfileUpdated(user, _name, _bio);
    }
    function getProfile(address _user) public view returns (string memory name, string memory bio) {
        require(profiles[_user].exists, "Profile does not exist");
        Profile memory userProfile = profiles[_user];
        return (userProfile.name, userProfile.bio);
    }
    function getMyProfile() public view returns (string memory name, string memory bio) {
        return getProfile(msg.sender);
    }
    function hasProfile(address _user) public view returns (bool) {
        return profiles[_user].exists;
    }
    function doIHaveProfile() public view returns (bool) {
        return hasProfile(msg.sender);
    }
    function getTotalUsers() public view returns (uint) {
        return userAddresses.length;
    }
    function getAllUsers() public view returns (address[] memory) {
        return userAddresses;
    }
    function deleteMyProfile() public {
        require(profiles[msg.sender].exists, "You don't have a profile to delete");
        delete profiles[msg.sender];
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == msg.sender) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break;
            }
        }
        
        emit ProfileUpdated(msg.sender, "", ""); 
    }
}