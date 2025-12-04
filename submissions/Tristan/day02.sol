// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract name_desc {
    string name;
    string description;
    string age;
    string sex;
    function addorchangenamedesc(string memory _name,string memory _desc,string memory _age,string memory _sex) public{
        name = _name;
        description = _desc;
        age = _age;
        sex = _sex;
    }
    function checknamedesc() public view returns (string memory,string memory,string memory,string memory) {
        return(name,description,age,sex);
    }
} 