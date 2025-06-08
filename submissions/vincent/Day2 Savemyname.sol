// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName{
    string Name;
    string Bio;

    function add(string memory newname, string memory newbio)public{
        Name = newname;
        Bio = newbio;
    }
       
    function retrieve() public view returns(string memory,string memory){
        return(Name,Bio);

    }

}