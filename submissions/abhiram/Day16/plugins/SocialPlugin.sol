// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../contracts/IPlugin.sol";

/**
 * @title SocialPlugin
 * @dev Plugin for managing social interactions between players
 * 
 * Allows players to follow each other, send messages, and manage social features.
 * Demonstrates delegatecall for social networking capabilities.
 */
contract SocialPlugin is IPlugin {
    // ============ Data Structures ============

    struct SocialProfile {
        uint256 followerCount;
        uint256 followingCount;
        string bio;
        bool publicProfile;
    }

    // ============ Events ============

    event PlayerFollowed(address indexed follower, address indexed followed);
    event PlayerUnfollowed(address indexed follower, address indexed unfollowed);
    event BioUpdated(address indexed player, string newBio);
    event ProfileVisited(address indexed visitor, address indexed profile);

    // ============ Errors ============

    error CannotFollowSelf(address player);
    error AlreadyFollowing(address follower, address followed);
    error NotFollowing(address follower, address followed);

    // ============ Plugin Interface ============

    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "Social Plugin";
    }

    // ============ Social Functions ============

    /**
     * @dev Gets the social profile of a player
     * 
     * Would access actual storage in production
     * 
     * @param _player The player's address
     * @return The social profile information
     */
    function getSocialProfile(address _player) external pure returns (SocialProfile memory) {
        return SocialProfile({
            followerCount: 0,
            followingCount: 0,
            bio: "",
            publicProfile: true
        });
    }

    /**
     * @dev Updates the player's bio
     * 
     * @param _bio The new bio text
     */
    function updateBio(string calldata _bio) external {
        require(bytes(_bio).length <= 200, "Bio too long (max 200 chars)");

        emit BioUpdated(msg.sender, _bio);
    }

    /**
     * @dev Follows another player
     * 
     * When called via delegatecall, uses the caller's storage
     * 
     * @param _playerToFollow The address of the player to follow
     */
    function followPlayer(address _playerToFollow) external {
        require(_playerToFollow != address(0), "Invalid player address");
        require(_playerToFollow != msg.sender, "Cannot follow yourself");

        emit PlayerFollowed(msg.sender, _playerToFollow);
    }

    /**
     * @dev Unfollows another player
     * 
     * @param _playerToUnfollow The address of the player to unfollow
     */
    function unfollowPlayer(address _playerToUnfollow) external {
        require(_playerToUnfollow != address(0), "Invalid player address");
        require(_playerToUnfollow != msg.sender, "Cannot unfollow yourself");

        emit PlayerUnfollowed(msg.sender, _playerToUnfollow);
    }

    /**
     * @dev Gets the number of followers
     * 
     * @param _player The player's address
     * @return The follower count
     */
    function getFollowerCount(address _player) external pure returns (uint256) {
        return 0;
    }

    /**
     * @dev Gets the number of following
     * 
     * @param _player The player's address
     * @return The following count
     */
    function getFollowingCount(address _player) external pure returns (uint256) {
        return 0;
    }

    /**
     * @dev Checks if one player follows another
     * 
     * @param _follower The potential follower
     * @param _followed The potentially followed player
     * @return Whether the follow relationship exists
     */
    function isFollowing(address _follower, address _followed) external pure returns (bool) {
        return false;
    }

    /**
     * @dev Records a profile visit
     * 
     * @param _profileVisited The profile being visited
     */
    function visitProfile(address _profileVisited) external {
        require(_profileVisited != address(0), "Invalid profile address");

        emit ProfileVisited(msg.sender, _profileVisited);
    }

    /**
     * @dev Makes the profile public or private
     * 
     * @param _public Whether the profile should be public
     */
    function setProfilePublic(bool _public) external {
        // Implementation would update storage
    }
}
