// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


contract Counter {
    uint256 public  counter = 0; //The initial value of the counter is 0 
 
function click()public { //This fuction will increse the counter value whenever you click this function
    counter++;
}


function getCount()public view returns(uint256) { //This function returns the counter value 
return  counter;
}


    
}
