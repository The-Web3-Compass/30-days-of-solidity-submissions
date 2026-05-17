 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.19;


 contract ClickCounter {

    uint256 counter=0;

    function increase() public  {
        counter++;
    }

    function decrease() public  {
        counter--;
    }

    function reset() public  {
        counter=0;
    }
    function getCounter() public view returns(uint256){
        return counter;
    }
 }
 
