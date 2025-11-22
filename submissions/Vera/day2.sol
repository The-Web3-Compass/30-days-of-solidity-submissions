// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PersonalInfo {
    string name;
    string bio;
    function add(string memory _name,string memory _bio) public {
        name = _name;
        bio = _bio;
    }
    function retrieve() public view returns (string memory, string memory){
        return (name,bio);
    }
    function addAndRetrieve(string memory _name, string memory _bio) public returns (string memory, string memory){
        name = _name;
        bio = _bio;
        // this.add(_name, _bio);
        return (name, bio);
    }
}