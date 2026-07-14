// SPDX-License-Identifier：MIT
pragma solidity ^0.8.0;
contract SaveMyName {
   string Name;
   string Bio;

   function add(string memory _name,string memory _bio) public{
      Name=_name;
      Bio=_bio;
}
   function retrieve() public view returns(string memory,string memory){
    return(Name,Bio);
   }
   function SaveAndRetrieve(string memory _name,string memory _bio)public returns(string memory,string memory){
    Name=_name;
    Bio=_bio;
    return(Name,Bio);
   }
   }
