// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SaveMyName {
    string public name;
    string public bio;
    
    event ProfileUpdated(address indexed user, string name, string bio);
    
    function add(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
        emit ProfileUpdated(msg.sender, _name, _bio);
    }
    
    function retrieve() public view returns(string memory, string memory) {
        return (name, bio);
    }
    
    function getName() public view returns(string memory) {
        return name;
    }
    
    function getBio() public view returns(string memory) {
        return bio;
    }
}