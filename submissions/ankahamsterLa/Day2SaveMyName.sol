// SPDX-License-Identifier:MIT

pragma solidity ^0.8.2;

// add and retrieve the information on the chain
contract SaveMyName{
    // define state variable
    // string: kind of datatype which presents text data
    string name;
    string bio;

    //add the information on the chain
    // "Memory" means temporary storage when the function is running.
    // "Storage" means permant storage on the blockchain.
    function add(string memory _name,string memory _bio) public{
        name=_name;
        bio=_bio;
    }

    //retrieve the information on the chain
    // The view keyword tells Solidity that this function only reads data and does not modify the blockchain.
    // The "rerturns()" means return some state or memory variables 
    function retrieve() public view returns(string memory, string memory){
        return(name,bio);
    }



}