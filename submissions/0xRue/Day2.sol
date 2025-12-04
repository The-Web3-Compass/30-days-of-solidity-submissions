// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName {
    string name;
    string bio;
    string age;
    string job;
    
    function add(string memory _name, string memory _bio) public {
        name = _name;
        bio = _bio;
    }
    function retrieve() public view returns(string memory, string memory) {
        return (name, bio);//必须需要这个函数，public只能返回单个变量，且这里这些变量本身都没有public
    }

    function SaveAndRetrieve(string memory _name, string memory _bio, string memory _age, string memory _job) public returns(string memory, string memory, string memory, string memory) {
        name = _name;
        bio = _bio;
        age = _age;
        job = _job;
        return (name, bio, age, job);
    }
}


