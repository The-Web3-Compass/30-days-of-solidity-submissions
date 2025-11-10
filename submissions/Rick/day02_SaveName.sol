// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract SaveName{

    string name;
    string age;

    function add(string memory _name,string memory _age) public {
        name = _name;
        age = _age;
    }

    function getAll() public  view returns (string memory,string memory){
        return (name,age);
    }

    function saveAndGet(string memory _name,string memory _age) public returns (string memory,string memory){
        name = _name;
        age = _age;
        return (name,age);
    }

} 