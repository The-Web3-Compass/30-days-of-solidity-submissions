//SPDX-License-Identifier: MIT
//Software Package Data Exchange

pragma solidity ^0.8.0;

contract SaveMyName{

    string name; // declared a private variable
    //🚩private variable & public variable:
    // for public variables, solidity will generate a getter function automatically, in remix will be a button to return the value 
    // for private ones we have to use retrieve function manually to return them
    string bio;

    function add( string memory _name, string memory _bio) public{ 
        //🚩memory&storage ：where the variable stored
        // memory: temporarily save, will disappear after function is excuted; for function usually use memory type
        // storage: permanently save on blockchain

        //🚩string is reference type
        // which saving location but not value itself, so memory/strorage need to be added; in stead, int is value type

        name = _name;
        bio = _bio;
    }

    function retrieve() public view returns(string memory, string memory){ 
        // 🚩view: means making no change to blockchain, only viewing, no gas cost!!
        // returns：a delaration that It's going to return blabla, mind the "s"
        return(name, bio);
    } 

    function AddAndRetrieve( string memory _name, string memory _bio) public returns( string memory, string memory){
        name = _name;
        bio = _bio;
        return (name, bio);
    }
}

//input formart： "Alice", "DJ"