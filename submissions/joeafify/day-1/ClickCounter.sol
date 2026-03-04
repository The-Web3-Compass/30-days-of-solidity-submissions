// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

contract ClickCounter {
    uint public number;
    address public owner;

    event Incremented(uint newValue);
    event Decremented(uint newValue);
    event Reset();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function increment() public {
        number++;
        emit Incremented(number);
    }

    function decrement() public {
        require(number > 0, "Number must be greater than 0");
        number--;
        emit Decremented(number);
    }

    function reset() public onlyOwner {
        number = 0;
        emit Reset();
    }
}