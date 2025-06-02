// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;



contract SaveName {
//state variables 
string public  s_name;
string public  s_bio;

//This function takes two parameter user and save it in our state variables 
//In this parameter we use memory beacause we modifiy our state  s_name => name(user input)

function setInfo (string memory name , string memory bio)public   { 

s_name = name;
s_bio = bio;


}

//This function retrive the infomation which is given by user after that we pass an arguments which is (string memory) so why i used this
//The cause is the string in solidity is bytes of arrays and this arrays is dynamaic arrays that's way they need data location 
function retriveInfo() public  view returns(string memory, string memory){  

    return  (s_name,s_bio);
}
}
