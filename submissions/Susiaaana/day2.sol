// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName{
    string name;
    string bios;

    function add (string memory _name, string memory _bios) public {
        name = _name;
        bios = _bios;
    }

    function retrieve () public view returns (string memory, string memory) {
        return (name, bios);
    }

}