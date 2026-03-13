// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint256 public counter;

    function click() public {
        counter++;
    }

    // this allows us to reset the counter
    function reset() public {
        counter = 0;
    }

    function resert() public {
        counter = 0;
    }

    function decrement() public {
        require(counter > 0, "Counter is already at zero");
        counter--;
    }

    mapping(address => uint256) public clickcByUser;

    function click() public {
        counter++;
        clicksByUser[msg.snder]++;
    }

    event Clicked(address indexed user, uint256 newCount);

    function click() public {
        counter++;
        emit Clicked(msg.sender, counter);
    }
}