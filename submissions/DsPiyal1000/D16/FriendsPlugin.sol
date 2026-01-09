// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FriendsPlugin {
    mapping(address => address[]) private friends;
    mapping(address => mapping(address => bool)) private isFriend;

    event FriendAdded(address indexed user, address indexed friend);

    function addFriend(address user, address friend) external {
        require(user != address(0) && friend != address(0), "Invalid address");
        require(user != friend, "Cannot add self as friend");
        require(!isFriend[user][friend], "Friend already added");
        
        friends[user].push(friend);
        isFriend[user][friend] = true;
        emit FriendAdded(user, friend);
    }

    function getFriends(address user) external view returns (address[] memory) {
        return friends[user];
    }
}