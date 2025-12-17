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

// Simple Profile Storage
// User can store names and biographies
contract SaveMyName {
    
    struct UserProfile {
        string name;
        string bio;
    }

    mapping(address => UserProfile) private profiles;

    // Event for transparency
    // event ProfileUpdated(address indexed user, string name, string bio);

    // name (e.g. "Alice")
    // bio (e.g. "I build dApps")
    function setProfile(string calldata name, string calldata bio) 
             external {

        profiles[msg.sender] = UserProfile(name, bio);
       // emit ProfileUpdated(msg.sender, name, bio);
    }

    function getProfile() external view returns 
            (string memory name, string memory bio) {

        UserProfile memory profile = profiles[msg.sender];
        return (profile.name, profile.bio);
    }

    /*function getProfileOf(address user) external view returns 
             (string memory name, string memory bio) {
                
        UserProfile memory profile = profiles[user];
        return (profile.name, profile.bio);
    } */
}
