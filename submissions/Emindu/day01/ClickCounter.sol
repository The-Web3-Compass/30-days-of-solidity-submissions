pragma solidity ^0.8.0;

contract DigitalClicker {
    
    uint public count;

    function click() public {
        count += 1;
    }

    function decrement() public {
        require(count > 0, "The clicker cannot go below zero.");
        count -= 1;
    }
}