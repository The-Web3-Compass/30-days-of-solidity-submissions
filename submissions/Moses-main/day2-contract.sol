// SPDX-License-Identifier: MIT

pragma solidity 0.5.17 < 0.8.2;

// The code is a basic Solidity contract that stores and retrieves user data, specifically name and status.
// Day 2
contract SaveMyName {
    string public name;
    bool public isActive = false;

    // enter the user name during deployment
    constructor(string memory _name) public {
        name = _name;
    }

    // change the user status
    function changeStatus() external view  returns (bool){
        if(isActive == false ){
            return false;
        } else {
            return true;
        }
    }

    function get_status() public view returns(bool) {
        isActive;
    }

    function get_name() public view returns(string memory) {
        return name;
    }

    function set_name(string memory _new_name) public {
        name = _new_name;
    }
}