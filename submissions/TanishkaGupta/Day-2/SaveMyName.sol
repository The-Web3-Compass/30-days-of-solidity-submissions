// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract SaveMyName {
    string private _name;
    string private _bio;
    bool private _isRegistered;

    function register(string memory name, string memory bio) public {
        _name = name;
        _bio = bio;
        _isRegistered = true;
    }

    function getName() public view returns (string memory) {
        return _name;
    }

    function getBio() public view returns (string memory) {
        return _bio;
    }

    function isRegistered() public view returns (bool) {
        return _isRegistered;
    }
}