//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SaveMyName{
    string name;
    string bio;

    function save(string memory _name, string memory _bio) public returns(string memory){
        if (bytes(_name).length == 0) { 
            return("Name cannot be empty!");
        }
        if (bytes(_bio).length == 0) {
            return("Bio cannot be empty!");
        }

        name = _name;
        bio = _bio; 
        return("saved successfully!");
    }
    
    function retrieve() public view returns(string memory,string memory){
        return (name,bio);
    }

}