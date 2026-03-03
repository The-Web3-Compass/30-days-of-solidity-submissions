// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    string public name;
    string public bio;
    bool public isActive;

    function add(string memory _name, string memory _bio) public {
        require(bytes(_bio).length <= 280, "Bio too long");
        name = _name;
        bio = _bio;
        isActive = true;
    }

    function retrieve()
        public
        view
        returns (string memory, string memory, bool)
    {
        return (name, bio, isActive);
    }
}
