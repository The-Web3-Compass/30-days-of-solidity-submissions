// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SaveMyName {

    error SaveMyName__NameOrBioEmpty();

    event UserInfoAdded(string newName, string addBio);

    string private name;
    string private bio;

    function setName(string calldata _name, string calldata _bio) public {
        if(bytes(_name).length == 0 || bytes(_bio).length == 0 ) {
            revert SaveMyName__NameOrBioEmpty();
        }
        
        name = _name;
        bio = _bio;

        emit UserInfoAdded(name, bio);
    }

    function greet() public view returns(string memory) {
        return string(abi.encodePacked("Hello ", name));
    }

    function getUserInfo() public view returns(string memory) {
        return string(abi.encodePacked(name,": ", bio));
    }

    function getName() public view returns(string memory) {
        return name;
    }
    
    function getBio() public view returns(string memory) {
        return bio;
    }
}