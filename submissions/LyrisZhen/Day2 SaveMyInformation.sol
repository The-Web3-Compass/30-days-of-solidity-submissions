// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
contract SaveMyInformation{
    string name;
    string bio;

    function add(string memory NewName,string memory NewBio)public{
        name = NewName;
        bio = NewBio;
    }
    function retrieve ()public view returns(string memory,string memory){
        return (name,bio);
    }
}
