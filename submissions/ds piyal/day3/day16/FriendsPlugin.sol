// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract FriendsPlugin {
    mapping(address => address[]) private friends;

    event FriendAdded(address indexed user, address indexed friend);

    function addFriend(address user, address friend) external {
        friends[user].push(friend);
        emit FriendAdded(user, friend);
    }

    function getFriends(address user) external view returns (address[] memory) {
        return friends[user];
    }
}