// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract addMyName {
    string private name;
    string private bio;

    // Save name and bio to the blockchain
    function retrieve() public view returns (string memory, string memory) {
    return (name, bio);
    }

    // Read name and bio (view = no gas when called externally)
    function saveAndRetrieve(string memory _name, string memory _bio) public returns (string memory, string memory) {
    name = _name;
    bio = _bio;
    return (name, bio);
    }
}
