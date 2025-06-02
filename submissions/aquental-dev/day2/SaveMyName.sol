// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    // public variables : ease debugging
    string public name;
    string public bio;

    function set(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    function get() public view returns (string memory, string memory) {
        return (name, bio);
    }
}
