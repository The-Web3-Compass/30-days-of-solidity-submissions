// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract SaveProfiles {
     mapping(string => string) private profiles;

     modifier whenNameExists(string memory _name) {
        require(bytes(profiles[_name]).length > 0, "Name does not exist");
        _;
    }
    
    modifier whenNameNotExists(string memory _name) {
        require(bytes(profiles[_name]).length == 0, "Name already exists");
        _;
    }

     function setProfile(string memory _name, string memory _bio) 
        public 
        whenNameNotExists(_name) 
    {
        profiles[_name] = _bio;
    }

    function getProfile(string memory _name) 
        public 
        view 
        whenNameExists(_name) 
        returns (string memory) 
    {
        return profiles[_name];
    }
}
