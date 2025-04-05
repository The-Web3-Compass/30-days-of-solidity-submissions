// SPDX-License-identifier: MIT 

// This is the simplest contract to store and get the user details

pragma solidity ^0.8.18;

contract SaveMyName01 {

    string name;               
    string bio;                   
    bool status;                

    function setDetails (string memory _name, string memory _bio, bool _status) public {
        name = _name;                     // set the name 
        bio = _bio;                       // set the bio 
        status = _status;                 // set the statue - true or false 
    }

    function getDetails() public view returns (string memory, string memory, bool) {
        return (name, bio, status);       // get the details of the user 
    }
}
