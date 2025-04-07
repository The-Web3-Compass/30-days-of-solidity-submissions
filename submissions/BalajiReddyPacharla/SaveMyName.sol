// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract SaveMyName{

   struct user{ //custom data typem to store a username and their bio
    string userName;
    string bio; 
   }
   user[] public listofusers; //array of users

   mapping (string => string) public retrievebio; //mapping to retrieve bio by username 

   function adduser(string memory usernm, string memory userbio) public{ //function to push and map user's name to bio into array of users
    listofusers.push(user(usernm,userbio));
    retrievebio[usernm]=userbio;
   }
}
