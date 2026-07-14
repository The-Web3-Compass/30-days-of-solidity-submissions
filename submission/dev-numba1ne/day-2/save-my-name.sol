// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyUserProfile {
    // Private state variables (not directly accessible outside the contract)
    string private _name;
    string private _bio;
    uint256 private _age;
    string private _profession;
    string private _email;

    // Stores all user data in one transaction
    function addProfile(
        string memory name,
        string memory bio,
        uint256 age,
        string memory profession,
        string memory email
    ) public {
        _name = name;
        _bio = bio;
        _age = age;
        _profession = profession;
        _email = email;
    }

    // Retrieves all user data at once
    function getProfile() public view returns (
        string memory name,
        string memory bio,
        uint256 age,
        string memory profession,
        string memory email
    ) {
        return (_name, _bio, _age, _profession, _email);
    }
}
