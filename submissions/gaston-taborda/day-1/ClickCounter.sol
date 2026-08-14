// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    // event
    event Clicked(address indexed user, uint256 newCount);

    // variables
    uint256 public counter;
    mapping(address => uint256) public clicksByUser;

    function click() public {
        counter++;
        clicksByUser[msg.sender]++;
        emit Clicked(msg.sender, clicksByUser[msg.sender]);
    }

    function reset() public {
        counter = 0;
    }

    function decrement() public {
        require(counter > 0, "Counter is already at zero");
        counter--;
    }
}
