//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/** @title SaveMyName
 *  @dev A simple contract to save and retrieve a name and bio.
 */
contract SaveMyName {
    string public name; // User's name
    string public bio; // User's bio

    // Function to save name and bio
    function saveInfo(string calldata _name, string calldata _bio) public {
        name = _name;
        bio = _bio;
    }

    // Function to retrieve name and bio
    function getInfo() public view returns (string memory, string memory) {
        return (name, bio);
    }
}