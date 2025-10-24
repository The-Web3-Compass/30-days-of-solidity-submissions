// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter{

    uint256 public counter;

    //increase by 1
    function click() public {
        counter++;
    }
    
    //reset counter
    function reset() public{
        counter = 0;
    }

    //decrease by 1
    function decrease() public{
        require(counter > 0 , "Counter cannot go below zero");
        counter--;
    }

    //return number
     function getCounter() public view returns (uint256){
        return counter;
    }

    //Multiple Clicks
    function multipleClicks(uint256 times) public{
        require(times > 0, "Number must be greater than zero");
        counter += times;
    }
}