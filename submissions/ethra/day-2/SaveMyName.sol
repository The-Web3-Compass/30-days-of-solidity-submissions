// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract SaveMyName {

    string public name;
    string public bio;
    bool public setting;

    function saveData(string calldata _name, string calldata _bio, bool _setting) public {
        name = _name;
        bio = _bio;
        setting = _setting;
    }

    function getData() public view returns (string memory, string memory, bool) {
        return(name, bio, setting);
    }
}