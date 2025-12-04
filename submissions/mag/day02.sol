//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract SaveMyName{
    string name;
    string bio:
    string email;
    function add (string memory _name,string memory _bio,string memory _email)public{
        name = _name;
        bio = _bio;
        email = _email;
    }
    function retrive()public view returns(string memory,string memory,string memory){
        return(name,bio,email);
    }
}
//updated for day02 submissions