// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SaveMyName {
    struct User {
        bytes32 name;
        bytes32 bio;
    }

    mapping(address => User) public users;

    constructor() {}

    function save(bytes32 _name, bytes32 _bio) external {
        User storage user = users[msg.sender];
        user.name = _name;
        user.bio = _bio;
    }
}