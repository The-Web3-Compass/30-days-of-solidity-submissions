// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    struct Profile {
        string name;
        string bio;
    }

    mapping(address => Profile) private profiles;

    function add(string memory _name, string memory _bio) public {
        profiles[msg.sender] = Profile(_name, _bio);
    }

    function retrieve(address _user) public view returns (string memory, string memory) {
        Profile memory p = profiles[_user];
        return (p.name, p.bio);
    }
}
