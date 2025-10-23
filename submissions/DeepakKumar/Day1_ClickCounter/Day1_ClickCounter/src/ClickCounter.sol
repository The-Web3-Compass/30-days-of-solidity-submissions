// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ClickCounter {
    // State variable to store number of clicks
    uint256 public count;

    // Event to log each click
    event Clicked(address indexed user, uint256 newCount);

    // Function to increment the counter
    function click() public {
        count += 1;
        emit Clicked(msg.sender, count); // log who clicked + new count
    }

    // Function to decrement the counter
    function unclick() public {
        require(count > 0, "Counter is already zero"); // safety
        count -= 1;
        emit Clicked(msg.sender, count);
    }

    // Function to reset the counter
    function reset() public {
        count = 0;
        emit Clicked(msg.sender, count);
    }

    // Getter function (though 'count' is public already)
    function getCount() public view returns (uint256) {
        return count;
    }
}
