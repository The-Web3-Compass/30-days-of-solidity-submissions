// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FriendsPlugin
 * @dev Manage player friendship connections. Works with PluginStore.
 */
contract FriendsPlugin {
    mapping(address => address[]) private friendsList;
    mapping(address => mapping(address => bool)) private isFriend;

    /// @notice Add a new friend for a player.
    function addFriend(address user, address newFriend) public {
        require(user != newFriend, "Cannot add self");
        require(!isFriend[user][newFriend], "Already friends");

        friendsList[user].push(newFriend);
        isFriend[user][newFriend] = true;
    }

    /// @notice Remove an existing friend.
    function removeFriend(address user, address friendAddr) public {
        require(isFriend[user][friendAddr], "Not friends");

        address[] storage list = friendsList[user];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == friendAddr) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
        isFriend[user][friendAddr] = false;
    }

    /// @notice Get all friends of a user.
    function getFriends(address user) public view returns (address[] memory) {
        return friendsList[user];
    }

    /// @notice Check if two users are friends.
    function areFriends(address user, address other) public view returns (bool) {
        return isFriend[user][other];
    }
}
