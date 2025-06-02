// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleCounter {

    uint public counter;
    
    constructor() {
        counter = 0; 
    }
    
    function increment() public {
        counter = counter + 1;  // Increment by 1
        
    }
    
   
    function getCount() public view returns (uint) {
        return counter;
    }
    
    function decrement() public {
        
        require(counter > 0, "Counter cannot go below zero");
        counter = counter - 1;
    }
    
    function reset() public {
        counter = 0;
    }
    
    function setCount(uint _newCount) public {
        counter = _newCount;
    }
}