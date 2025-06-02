// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SaveMyName{

    string name;
    string bio;
    uint256 age;
    string profession;
    string location;

    function set 
    (string memory Name, 
    string memory Bio, 
    uint256 Age, 
    string memory Profession, 
    string memory Location) 
    public 
    {

        name = Name;
        bio = Bio;
        age = Age;
        profession = Profession;
        location= Location;

    }

    function read() 
    public 
    view //read only, no gas fees consumed
    returns
     (string memory Name, 
    string memory Bio, 
    uint256  Age, 
    string memory Profession, 
    string memory Location)

    {
        return (name, bio, age, profession, location);
    }
    
}