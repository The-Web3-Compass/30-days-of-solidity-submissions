// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ClickCounter {
    uint public count; // Initialise à 0 par défaut
    
    function click() public {
        count++; // Incrémente le compteur de 1
    }
    
    function getCount() public view returns (uint) {
        return count;
    }
}