// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

/**
 * @title SaveMyName
 * @author Carlos I Jimenez
 * @notice A simple contract for storing a user's name and bio
 * @dev Allows a single user to save and retrieve their profile information
 */
contract SaveMyName {
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice The user's name stored on the blockchain
    string public s_name;
    
    /// @notice The user's bio stored on the blockchain
    string public s_bio;
    
    /// @notice Indicates whether a profile has been saved
    bool public s_hasProfile;
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emitted when a profile is saved
    /// @param name The name that was saved
    /// @param bio The bio that was saved
    event ProfileSaved(string name, string bio);
    
    /// @notice Emitted when the profile is deleted
    event ProfileDeleted();
    
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Thrown when trying to save an empty name
    error SaveMyName__NameCannotBeEmpty();
    
    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Saves or updates the user's profile
     * @dev Stores the name and bio on the blockchain
     * @param _name The user's name (cannot be empty)
     * @param _bio The user's bio (can be empty)
     */
    function saveProfile(string calldata _name, string calldata _bio) external {
        if (bytes(_name).length == 0) {
            revert SaveMyName__NameCannotBeEmpty();
        }
        
        s_name = _name;
        s_bio = _bio;
        s_hasProfile = true;
        
        emit ProfileSaved(_name, _bio);
    }
    
    /**
     * @notice Deletes the stored profile
     * @dev Resets all profile data to default values
     */
    function deleteProfile() external {
        delete s_name;
        delete s_bio;
        s_hasProfile = false;
        
        emit ProfileDeleted();
    }
    
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Retrieves the stored profile
     * @dev Returns the name, bio, and profile status
     * @return name The stored name
     * @return bio The stored bio
     * @return hasProfile Whether a profile exists
     */
    function getProfile() external view returns (
        string memory name,
        string memory bio,
        bool hasProfile
    ) {
        return (s_name, s_bio, s_hasProfile);
    }
}