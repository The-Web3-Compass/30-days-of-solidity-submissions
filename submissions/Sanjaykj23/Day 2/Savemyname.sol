// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
contract Savemyname{
    string name;
    string bio;
    uint age;
    bool vote=false;
    function addName(string memory _name)public{
        name=_name;
    }
    function addBio(string memory _bio)public {
        bio=_bio;
    }
    function addAge(uint _age)public {
        age=_age;
        if(age>=18){
            vote=true;
        }
    }
    function getName()public view returns(string memory){
        return name;
    }
    function getBio()public view returns(string memory){
        return bio;
    }
    function eligibleToVote()public view returns(bool){
        return  vote;
    }
}