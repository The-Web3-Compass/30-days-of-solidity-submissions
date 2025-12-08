// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleProfile {
    string public name;
    string public bio;

    function setProfile(string memory _name , string memory _bio) public {
        name = _name;
        bio = _bio;
    }
}