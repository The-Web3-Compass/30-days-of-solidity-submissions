// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract MyProfile {
    string name;
    string bio;

    function AddProfile(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;

    }

    function Retrieve() public view returns (string memory, string memory) {
        return (name, bio); // Returning both name and bioname
}
}