// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    
    struct Profile {
        uint256 id;
        string name;
        string bio;
    }
    
    Profile[] public listOfProfiles;
    
    function addMyProfile (string memory _name, string memory _bio) public {
        uint256 length = listOfProfiles.length;
        listOfProfiles.push(Profile(length+1, _name, _bio));
    }

    function getLatestProfile () public view returns (Profile memory) {
        return listOfProfiles[listOfProfiles.length - 1];
    }

   
}