// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract saveData {
    struct User{
        string name;
        string bio;
    }

    mapping (address => User) public profile;

    function createProfile(string memory _name, string memory _bio) public {
        Profile[msg.sender] = User({
            
        })
    }
}