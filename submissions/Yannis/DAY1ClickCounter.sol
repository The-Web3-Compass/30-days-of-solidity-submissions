//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract ClickCounter{
    
    uint256 public counter;
    
    function click() public{
    counter++;
    }

    function getCounter() public view returns (uint256){
        return counter;
    }
}