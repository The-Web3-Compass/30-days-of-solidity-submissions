/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SaveMyName {
    struct Person{
        string name;
        string bio;
        uint age;
    }
    Person[]  person;

    function saveName(
        string calldata _name, 
        string calldata _bio, 
        uint _age) public {

            person.push(Person(_name, _bio, _age));
        }
    

    function getPerson(uint _index) public view returns(string memory, string memory, uint){
        Person memory _person = person[_index];
        return(_person.name, _person.bio, _person.age);
    }



}
