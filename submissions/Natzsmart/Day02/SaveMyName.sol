/*---------------------------------------------------------------------------
  File:   SaveMyName.sol
  Author: Natzsmart 
  Date:   04/02/2025
  Description:
    Imagine creating a basic profile. You'll make a contract where users can 
    save their name (like 'Alice') and a short bio (like 'I build dApps'). 
    You'll learn how to store text (using `string`) on the blockchain. Then, 
    you'll create functions to let users save and retrieve this information. 
    This demonstrates how to store and retrieve data on the blockchain, 
    essential for building profiles or user data storage.
----------------------------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Simple Profile Storage
contract SaveMyName {

        string name;
        string bio;

    
    function add(string memory _name, string memory _bio) 
             public {

        name = _name;
        bio = _bio;
    }

    function retrieve() public view returns(string memory, string memory) {
        return(name, bio);
    }

    function SaveAndRetrieve(string memory _name, string memory _bio) public returns(string memory, string memory){
        name = _name;
        bio=_bio;

        return (name, bio); 
    }

}