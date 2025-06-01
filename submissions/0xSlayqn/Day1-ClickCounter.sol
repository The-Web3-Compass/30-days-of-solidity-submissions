// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract ClickCounter {


    uint256 public Counter = 0;


    function click_Increment() public returns(uint256) {
        // Counter++;
        Counter = Counter + 1;
        return Counter;
    }


    function click_Decrement() public returns (uint256) {
        // Counter--;
        Counter = Counter - 1;
        return Counter;
    }


    function getCounterValue () public view returns(uint256) {
        return Counter;
    }


}
