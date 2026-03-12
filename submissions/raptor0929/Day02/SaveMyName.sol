// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SaveMyName {
    struct User {
        string name;
        string bio;
    }

    mapping(address => User) public users;

    constructor() {}

    function save(string calldata _name, string calldata _bio) external {
        User storage user = users[msg.sender];
        user.name = _name;
        user.bio = _bio;
    }
}