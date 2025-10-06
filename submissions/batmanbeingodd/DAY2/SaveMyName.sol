//SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;
contract Name{
    string public yourName;
    string public addYourBio;
    uint public age;
  /*  function add(string memory name ,string memory bio) public{
        yourName = name;
        addYourBio= bio;
    }

    function retrieve() public view returns(string memory, string memory){
        return (yourName,addYourBio);
    } */

    function addAndRetrieve(string memory name, string memory bio,uint vayasu) public returns(string memory, string memory, uint){
        yourName= name;
        addYourBio= bio;
        age =vayasu;
       return(yourName,addYourBio,age);



    }




}