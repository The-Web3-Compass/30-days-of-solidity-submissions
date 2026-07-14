// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ClickCounter{
    uint256 count;

    function click()public returns(uint256){
        return count += 1;
    }

    // Get the count value.
    function getCount()public view returns(uint256){
        return count;
    }

}