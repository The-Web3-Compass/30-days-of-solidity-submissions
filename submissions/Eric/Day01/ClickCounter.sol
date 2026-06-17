
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract Counter {

    uint private counter;
    

    function click() public {
        counter += 1;
    }

    function decrease() public {
        if (counter>0)
        {
        counter -= 1;
        }
        else 
        {
            counter = 0;
        }
    }

    function reset() public{
        counter=0;
    }

    function getCounter() public view returns(uint) {
        return counter;
    }
}