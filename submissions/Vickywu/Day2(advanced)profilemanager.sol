// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ProfileManager {
    struct Profile {
        string name;
        string bio;
        uint256 age;  
        string occupation;
    }

mapping(address => Profile) private profiles;

event ProfileUpdated(
        address indexed user,
        string name,
        string bio,
        uint256 age,
        string occupation
    );

modifier validAge(uint256 _age) {
        require(_age > 0 && _age < 150, "Invalid age");
        _;
    }

function saveAndRetrieve(
        string memory _name,
        string memory _bio,
        uint256 _age,   
        string memory _occupation
    ) external validAge(_age) returns (Profile memory) {

        Profile storage profile = profiles[msg.sender];
        profile.name = _name;
        profile.bio = _bio;
        profile.age = _age;
        profile.occupation = _occupation;

        emit ProfileUpdated(msg.sender, _name, _bio, _age, _occupation);

        return profile;
    }

    function getProfile(address _user) external view returns (Profile memory) {
        return profiles[_user];
    }

}