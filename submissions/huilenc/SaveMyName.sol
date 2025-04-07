// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract SaveMyName {
    string public name;
    string public bio;

    function saveInfo(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }

    function getInfo() public view returns (string memory, string memory) {
        return (name, bio);
    }
}
