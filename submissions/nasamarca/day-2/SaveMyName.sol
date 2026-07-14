// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SaveMyName
 * @author Nadiatus Salam
 * @notice A simple profile storage contract allowing users to save and retrieve their name and bio.
 * @dev Solidity fundamentals exercise: string & bool state variables, storage vs memory.
 */
contract SaveMyName {
    
    // State variables stored on the blockchain
    string public name;
    string public bio;
    bool public hasProfile;

    // Events to log changes efficiently
    event ProfileUpdated(address indexed user, string newName, string newBio);
    event ProfileDeleted(address indexed user);

    // Custom error for gas efficiency
    error ProfileAlreadyExists();
    error ProfileNotFound();

    /**
     * @notice Saves or updates the user's name and bio.
     * @dev Inputs are in `memory` because they are temporary during execution.
     * @param _name The name to store.
     * @param _bio The short bio to store.
     */
    function saveProfile(string memory _name, string memory _bio) external {
        name = _name;
        bio = _bio;
        hasProfile = true;
        
        emit ProfileUpdated(msg.sender, _name, _bio);
    }

    /**
     * @notice Retrieves the stored profile information.
     * @dev Explicit getter function (though public variables create one automatically).
     * @return _name The stored name.
     * @return _bio The stored bio.
     * @return _hasProfile Boolean indicating if a profile exists.
     */
    function getProfile() external view returns (string memory _name, string memory _bio, bool _hasProfile) {
        return (name, bio, hasProfile);
    }

    /**
     * @notice Deletes the stored profile.
     * @dev Resets string variables to empty strings and bool to false.
     */
    function deleteProfile() external {
        if (!hasProfile) revert ProfileNotFound();

        delete name;
        delete bio;
        hasProfile = false;

        emit ProfileDeleted(msg.sender);
    }
}