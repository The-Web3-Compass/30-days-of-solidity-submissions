// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CounterContract {
    uint256 public counter;
    function click () public {
        counter++;
    }
    function reset () public  {
        counter = 0;
    }
    function decrease() public  {
        if(counter > 0){
            counter--;
        }
    }
    function getCounter() public view returns (uint256)  {
        return counter;
    }
    function clickMultiple(uint256 times) public {
        counter=counter*times;
    }
}