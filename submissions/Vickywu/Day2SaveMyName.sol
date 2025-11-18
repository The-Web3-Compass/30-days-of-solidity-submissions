// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SaveMyname {
    
    string name;  // 一个名字
    string bio;   //一个简介
    string age;
    string occupation;

    function add (string memory _name, string memory _bio, string memory _age, string memory _occupation )public {
        name = _name;
        bio = _bio;
        age = _age;
        occupation = _occupation;
    }

    function retrieve() public view returns(string memory, string memory, string memory, string memory){
        return (name,bio,age,occupation);
    }
    
}