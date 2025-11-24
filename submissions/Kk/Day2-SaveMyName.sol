// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    //state variables, permanently stored on blockchain
    string name; 
    string bio;

    //users store function
    function add(string memory _name, string memory _bio) public {
        //underscore(_) represents function internal parameters
        name = _name;
        bio = _bio;
    }

    //retrieve data, view keyword makes this function only reads data, cannot modify 
    function retrieve() public view returns (string memory, string memory) {
        return (name, bio);
    }

    //2 functions in 1
    function saveAndRetrieve(string memory _name, string memory _bio) public returns (string memory, string memory){
        name = _name;
        bio = _bio;
        return (name, bio);
    }

}
