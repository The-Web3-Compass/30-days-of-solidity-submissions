// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract SaveMyName {
    string name;
    string bio;

    function saveProfile ( string memory _name, string memory _bio ) public {
        name = _name;
        bio = _bio;
    }

    function getProfile () public view returns (string memory , string memory) {
        return (name ,  bio);
    }
}