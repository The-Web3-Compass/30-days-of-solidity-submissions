/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    // 1. State Variables (Stored permanently on the blockchain)
    string public name;
    string public bio;
    bool public isActive;

    // 2. Save Function (Writes data)
    // We MUST use 'memory' for strings passed into functions so the EVM knows 
    // to only hold them temporarily while the function runs.
    function saveProfile(string memory _name, string memory _bio, bool _isActive) public {
        // Safety checks to optimize gas and prevent spam
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_bio).length <= 280, "Bio cannot exceed 280 characters");

        // Update the permanent state variables
        name = _name;
        bio = _bio;
        isActive = _isActive;
    }

    // 3. Retrieve Function (Reads data)
    // 'view' means this function costs zero gas to call from the outside!
    function getProfile() public view returns (string memory, string memory, bool) {
        return (name, bio, isActive);
    }
}