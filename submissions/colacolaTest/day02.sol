//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SaveMyName{
    mapping(address=>string) public names;

    function setName(string memory _name) public {
        names[msg.sender]= _name;   
    }

    function getName(address _user) public view returns(string memory){
        return names[_user];
    }

}
