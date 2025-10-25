//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract SaveMyName{
    string name;
    string bio;
    string gender;
    function add(string memory _name,string memory _bio) public{
        name = _name;
        bio = _bio;
    }
    function retrieve() public view returns(string memory,string memory){
        return(name,bio);
    }
    //增加了性别属性
    function saveAndRetrieve(string memory _name,string memory _bio,string memory _gender) public returns(string memory,string memory,string memory){
         name = _name;
         bio = _bio;
         gender = _gender;
        return(name,bio,gender);

    }
}