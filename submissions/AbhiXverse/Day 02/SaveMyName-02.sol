// SPDX-License-Identifier: MIT 

// One level up contract to store and get the users details 

pragma solidity ^0.8.18;

contract SaveMyName {


    // Defined the struct to store the user details 
    Struct Users {
        string name;
        string bio;
        bool status;
    }
    
    // Array to store all user profiles 
    Users[] public Profiles;             // you can get details using index 0, 1, 2, etc

    // Mapping to store user status by name 
    mapping (string => bool) public userstatus;

    // function to set the user details 
    function setDetails (string memory name, string memory bio, bool status) public {
        Profiles.push(Users(name, bio, status));           // push the user details to the array 
        userstatus[name] = status;                         // stores the status of the user by name 
    }
}


