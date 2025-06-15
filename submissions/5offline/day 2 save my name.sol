//SPDX-License-Identifier:MIX
pragma solidity^0.8.0;

contract savemyname{
string name;
string bio;
string age;
string job;
string city;

function add(string memory _name, string memory _bio, string memory _age, string memory _job, string memory _city )public{

    name=_name;
    bio=_bio;
    age=_age;
    job=_job;
    city=_city;
}

function retrieve() public view returns (string memory,string memory, string memory, string memory, string memory){
    return(name,bio,age,job,city);

}

function saveandRetrieve(string memory _name, string memory _bio)public returns(string memory,string memory){

    name=_name;
    bio=_bio;
    return(name,bio);
}

}


