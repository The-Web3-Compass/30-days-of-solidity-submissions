// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract SaveMyName{
    error SetDetailsFirst();
    error NameIsMissing();
    error BioIsMissing();

    struct Person {
        string name;
        string bio;
    }
    // Person public me;
    mapping (address=> Person) private persons;

    modifier mustHaveDetailsSet() {
        Person storage _person = persons[msg.sender];
        if (bytes(_person.name).length == 0 || bytes(_person.bio).length == 0) revert SetDetailsFirst(); 
        _;
    }


    function setDetails(Person calldata _person) public {
        persons[msg.sender] = _person;
    }


    function getMyDetails() external view returns(Person memory) {
    return persons[msg.sender];
    }

    function updateBio(string calldata _bio) public mustHaveDetailsSet{
        if (bytes(_bio).length == 0) revert BioIsMissing();
        Person storage _person = persons[msg.sender];
        _person.bio  = _bio;  
    }

    function updateName(string calldata _name) public mustHaveDetailsSet{
        if (bytes(_name).length == 0 ) revert NameIsMissing();
        Person storage _person = persons[msg.sender];
        _person.name = _name;
    }
        

}