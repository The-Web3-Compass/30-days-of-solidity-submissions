// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract ClickCounter{

    uint256 public counter ;

    function click() public 
    {
        counter ++;
    }
    function decrement() public 
    {
        require(counter > 0, "Counter is already zero");
        counter --;
    }
    function reset() public {
        counter = 0 ;
    }

}