/*---------------------------------------------------------------------------
  File:   SaveMyName.sol
  Author: Marion Bohr
  Date:   04/02/2025
  Description:
    Imagine creating a basic profile. You'll make a contract where users can 
    save their name (like 'Alice') and a short bio (like 'I build dApps'). 
    You'll learn how to store text (using `string`) on the blockchain. Then, 
    you'll create functions to let users save and retrieve this information. 
    This demonstrates how to store and retrieve data on the blockchain, 
    essential for building profiles or user data storage.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Simple Profile Storage
/// @notice User can store names and biographies
contract SaveMyName {
    
    struct UserProfile {
        string name;
        string bio;
    }

    // Mapping: Address → Profile
    mapping(address => UserProfile) private _profiles;

    // Event for transparency
    event ProfileUpdated(address indexed user, string name, string bio);

    /// @notice stores/updates the profile of the given address
    /// @param name (e.g. "Alice")
    /// @param bio (e.g. "I build dApps")
    function setProfile(string calldata name, string calldata bio) 
             external {

        _profiles[msg.sender] = UserProfile(name, bio);
        emit ProfileUpdated(msg.sender, name, bio);
    }

    /// @notice returns the profile of the given address
    function getProfile() external view returns 
            (string memory name, string memory bio) {

        UserProfile memory profile = _profiles[msg.sender];
        return (profile.name, profile.bio);
    }

    /// @notice returns the profile of any address (publicly readable)
    function getProfileOf(address user) external view returns 
             (string memory name, string memory bio) {
                
        UserProfile memory profile = _profiles[user];
        return (profile.name, profile.bio);
    }
}