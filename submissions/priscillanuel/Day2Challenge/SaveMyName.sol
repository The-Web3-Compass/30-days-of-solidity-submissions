// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract SaveMyName{
    string MyName;
    string bio;

    function add(string memory _MyName, string memory _bio) public {
        MyName = _MyName;
        bio = _bio;
    }

    function retrieve() public view returns
     (string memory, string memory)
    {
        return (MyName, bio);
    }
        
}