// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SaveMyName{
    string public name;
    string public bio;

    function save(string memory myname, string memory mybio) public{
        // memory means it's only temporarily holding onto this string input, 
        // it gets discarded once this function completes execution.
        name = myname;
        bio = mybio;
    }

    function retrieve() public view returns(string memory, string memory){
        return(name, bio);
    }

}