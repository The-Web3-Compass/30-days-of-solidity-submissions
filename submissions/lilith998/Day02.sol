// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicProfile {
    // Struct to hold profile information
    struct Profile {
        string name;
        string bio;
    }
    
    // Mapping from user address to their profile
    mapping(address => Profile) public profiles;
    
    // Event emitted when a profile is updated
    event ProfileUpdated(address indexed user, string name, string bio);
    
    /**
     * @dev Stores or updates the profile for the message sender
     * @param _name The name to store (e.g., "Alice")
     * @param _bio The bio to store (e.g., "I build dApps")
     */
    function setProfile(string memory _name, string memory _bio) public {
        // Validate input - names and bios shouldn't be empty
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_bio).length > 0, "Bio cannot be empty");
        
        // Store the profile data
        profiles[msg.sender] = Profile({
            name: _name,
            bio: _bio
        });
        
        // Emit an event about the update
        emit ProfileUpdated(msg.sender, _name, _bio);
    }
    
    /**
     * @dev Retrieves the profile of the message sender
     * @return name The stored name
     * @return bio The stored bio
     */
    function getMyProfile() public view returns (string memory name, string memory bio) {
        Profile storage profile = profiles[msg.sender];
        return (profile.name, profile.bio);
    }
    
    /**
     * @dev Retrieves the profile of a given address
     * @param _user The address to look up
     * @return name The stored name
     * @return bio The stored bio
     */
    function getUserProfile(address _user) public view returns (string memory name, string memory bio) {
        Profile storage profile = profiles[_user];
        return (profile.name, profile.bio);
    }
}
