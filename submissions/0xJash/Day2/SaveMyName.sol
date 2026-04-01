// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SaveMyName {
    string public name;

    function saveName(string memory _name) public {
        name = _name;
    }

    function getName() public view returns (string memory){
        return name;
    }
}