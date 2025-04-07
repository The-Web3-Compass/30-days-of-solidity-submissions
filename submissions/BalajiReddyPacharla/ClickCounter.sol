// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract Clickcounter{
    uint public counter = 0;
    function click_increment()public {
        counter++;
    }
    function click_decrement() public{
        counter--;
    }
    function get_clickcount() view  public returns (uint) {
        return counter;
    }
}
