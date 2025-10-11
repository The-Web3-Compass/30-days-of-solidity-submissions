// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract X {

    string name;
    string bio;

    function set(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    function get() public view returns (string memory, string memory) {
        return (name, bio);
    }
    
    function setAndGet(string memory _name, string memory _bio) public returns (string memory, string memory) {
        name = _name;
        bio = _bio;
        return (name, bio);
    }
}