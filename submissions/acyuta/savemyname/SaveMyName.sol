// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SaveMyName {

    error SaveMyName__NameOrBioEmpty();

    event UserInfoAdded(string newName, string addBio);

    mapping(address => string) private names;
    mapping(address => string) private bios;

    function setName(string calldata _name, string calldata _bio) public {
        if(bytes(_name).length == 0 || bytes(_bio).length == 0 ) {
            revert SaveMyName__NameOrBioEmpty();
        }
    
        names[msg.sender] = _name;
        bios[msg.sender] = _bio;

        emit UserInfoAdded(_name, _bio);
    }

    function greet() public view returns(string memory) {
        return string(abi.encodePacked("Hello ", names[msg.sender]));
    }

    function getUserInfo() public view returns(string memory) {
        return string(abi.encodePacked(names[msg.sender],": ", bios[msg.sender]));
    }

    function getName() public view returns(string memory) {
        return names[msg.sender];
    }

    function getBio() public view returns(string memory) {
        return bios[msg.sender];
    }
    }
}