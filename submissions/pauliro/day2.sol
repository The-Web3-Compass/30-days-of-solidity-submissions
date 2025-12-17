// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
 /*
 Contract where users can save their name and a short bio.  
 Then, you'll create functions to let users save and retrieve this information. 
 */

contract SaveMyName {
   
    string name;
    string bio;


    function addInfo(string memory _name, string memory _bio) public {
        name =_name ;
        bio = _bio;
    }  

    function retrieveInfo() public view returns (string memory, string memory) {
        return (name, bio);
    }
}
