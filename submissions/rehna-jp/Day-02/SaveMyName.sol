// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SaveMyName{
    string name;
    string bio;
    bool profileCreated ;

    function SaveInfo(string memory _name, string memory _bio) external {
         name = _name;
         bio = _bio;
         profileCreated = true;
    }

    function retrieveInfo() external view returns(string memory, string memory, bool){
         return (name, bio, profileCreated);
    }
}