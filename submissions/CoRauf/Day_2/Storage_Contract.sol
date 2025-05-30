//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract SimpleStorage {

    string public name;

    function State_Name(string memory _name) public returns(string memory){
        name = _name;
        return name;
    }
}