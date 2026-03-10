// SPDX-License-Identifier: MIT
// @author 0xVexhappy
pragma solidity ^0.8.31;

contract SaveMyName{
    string public firstName;
    string public lastName;
    string public fullName;
    string public bio;
    bool public settingStatus;

    function add(string memory _firstName, string memory _lastName, string memory _bio) public {
        require(bytes(_firstName).length <= 32, 'name too long');
        require(bytes(_lastName).length <= 32, 'name too long');
        require(bytes(_bio).length <= 280, 'bio too long');
        firstName = _firstName;
        lastName = _lastName;
        bio = _bio;

    }

    function retrieve() public returns(string memory, string memory) {
        fullName = string(abi.encodePacked(firstName,lastName));
        return (fullName, bio);
    }
}
