//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SaveMyName{

    string name;
    string bio;
    uint age;
    string profession;
    string gender;
    

    function add(string memory _name,string memory _bio,uint _age,string memory _profession,string memory _gender) public{
        name=_name;
        bio=_bio;
        age=_age;
        profession=_profession;
        gender=_gender;
    }

    function retrieve() public view returns(string memory,string memory,uint,string memory,string memory){
        return (name,bio,age,profession,gender);
    }

}