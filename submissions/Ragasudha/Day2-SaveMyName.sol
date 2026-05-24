// SPDX-license-Identifier: MIT
pragma solidity ^0.8.0;
contract SaveMyName{
    string public name;
    string public bio;
    bool public isActive;
    function setProfile(string memory _name,string memory _bio) public{
        name=_name;
        bio=_bio;
        isActive=true;
    }
    function getProfile() public view returns (string memory,string memory,bool){
        return (name,bio,isActive);
    }
}