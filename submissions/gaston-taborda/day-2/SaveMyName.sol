// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    bytes32 public name;
    string public bio;

    function add(string memory _name, string memory _bio) public {
        require(bytes(_name).length <= 32, "Name too long");
        name = bytes32(bytes(_name));
        require(bytes(_bio).length <= 280, "Bio too long");
        bio = _bio;
    }

    function retrieve() public view returns (string memory, string memory) {
        return (string(abi.encodePacked(name)), bio);
    }
}
