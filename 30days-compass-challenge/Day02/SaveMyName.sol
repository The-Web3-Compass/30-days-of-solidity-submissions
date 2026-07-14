// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract UserProfile {
    string public name;
    string public bio;

    function saveProfile(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }
    
    function getProfile() public view returns (string memory, string memory) {
        return(name,bio);
    }
}