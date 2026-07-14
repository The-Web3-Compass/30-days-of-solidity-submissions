//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SaveMyName{
    string name;
    string bio;
    uint age;//The uint values are stored in the stack rather than in storage, so they can be read directly without needing to be loaded into memory.
    string job;

    function add(string memory _name,string memory _bio,uint _age,string memory _job) public{
        name=_name;
        bio=_bio;
        age=_age;
        job=_job;
    }
    function retrieve() public view returns(string memory,string memory,uint,string memory) {
        return(name,bio,age,job);
    }
    //function saveAndRetrieve(string memory _name,string memory _bio)public returns(string memory,string memory){
    //    name=_name;
    //    bio=_bio;
    //    return(name,bio);
    //}
}