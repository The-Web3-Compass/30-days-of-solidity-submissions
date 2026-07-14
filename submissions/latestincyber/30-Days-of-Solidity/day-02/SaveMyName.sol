// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    mapping(address => string) private names;
    mapping(address => string) private bios;

    function add(string memory _name, string memory _bio) public {
        names[msg.sender] = _name;
        bios[msg.sender] = _bio;
    }

    function retrieve() public view returns (string memory, string memory) {
        return (names[msg.sender], bios[msg.sender]);
    }
}