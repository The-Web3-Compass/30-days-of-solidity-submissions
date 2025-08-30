// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserProfile {
    string private _name;
    string private _bio;
    
    
    function setProfile(string memory name, string memory bio) public {
        _name = name;
        _bio = bio;
    }
    
    function getProfile() public view returns (string memory, string memory) {
        return (_name, _bio);
    }
}
