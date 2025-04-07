// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Profile Struct
/// @notice Represents the profile data of a user.
/// @dev Contains basic information like name and biography.
struct Profile {
    string name;
    string bio;
}

/// @notice Profile not found.
/// @param _userAddress user address.
error ProfileNotFound(address _userAddress);

/// @title SaveMyName
/// @author shivam
/// @notice This contract manages a basic profile for users by linking it to their wallet address.
/// @dev A mapping is used to store Profile objects mapped to user addresses. Requires users to set a name before they can set a bio.
contract SaveMyName {
    /// @dev Mapping of user address to their Profile
    mapping(address => Profile) private profiles;
     
    /// @notice Internal function to determine if a user has set their name
    /// @dev Checks if a profile is created for given address
    /// @param _userAddress wallet address of user
    /// @return bool true if user profile is set, i.e., name is not blank
    function _hasProfile(address _userAddress) internal view returns (bool) {
        // A profile is considered set if the name is not blank
        return bytes(profiles[_userAddress].name).length > 0;
    }

    /// @notice Gets the name for a specific user address
    /// @param _userAddress wallet address of user
    /// @return name the saved name for user
    /// @custom:error ProfileNotFound if profile for given address doesn't exist
    function getName(address _userAddress) public view returns (string memory) {
        if (!_hasProfile(_userAddress)) {
            revert ProfileNotFound(_userAddress);
        }
        return profiles[_userAddress].name;
    }

    /// @notice Gets the bio for a specific user address
    /// @param _userAddress wallet address of user
    /// @return bio the saved bio for user
    /// @custom:error ProfileNotFound if profile for given address doesn't exist
    function getBio(address _userAddress) public view returns (string memory) {
        if (!_hasProfile(_userAddress)) {
            revert ProfileNotFound(_userAddress);
        }
        return profiles[_userAddress].bio;
    }

    /// @notice Sets the name for caller's address, creates profile if not found
    /// @param _name name for user
    function setName(string calldata _name) public {
        require(bytes(_name).length > 0, "Name cannot be empty");
        profiles[msg.sender].name = _name;
    }

    /// @notice Sets the bio for caller's address
    /// @dev profile must be available for the caller's address
    /// @param _bio bio for user
    /// @custom:error ProfileNotFound if profile for caller's address doesn't exist
    function setBio(string calldata _bio) public {
        if (!_hasProfile(msg.sender)) {
            revert ProfileNotFound(msg.sender);
        }
        profiles[msg.sender].bio = _bio;
    }
}