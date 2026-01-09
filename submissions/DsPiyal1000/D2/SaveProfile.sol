// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SaveProfile {
    address private immutable _owner;
    string private _name;
    string private _bio;
    uint256 private _age;
    string private _profession;

    // --- Events ---
    event ProfileUpdated(
        string name,
        string bio,
        uint256 age,
        string profession
    );

    // --- Errors ---
    error Unauthorized();
    error EmptyName();

    constructor(
        string memory name_,
        string memory bio_,
        uint256 age_,
        string memory profession_
    ) {
        _owner = msg.sender;
        _updateProfile(name_, bio_, age_, profession_);
    }

    // --- External Functions ---
    function updateProfile(
        string memory name_,
        string memory bio_,
        uint256 age_,
        string memory profession_
    ) external {
        if (msg.sender != _owner) revert Unauthorized();
        if (bytes(name_).length == 0) revert EmptyName();

        _updateProfile(name_, bio_, age_, profession_);
    }

    function getInfo() external view returns (string memory, string memory, uint256, string memory)
    {
        return (_name, _bio, _age, _profession);
    }

    // --- Internal Functions ---
    function _updateProfile(
        string memory name_,
        string memory bio_,
        uint256 age_,
        string memory profession_
    ) private {
        _name = name_;
        _bio = bio_;
        _age = age_;
        _profession = profession_;

        emit ProfileUpdated(name_, bio_, age_, profession_);
    }
}