//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//every line in this contract will be stored on blockchain forever once deployed
contract ClickCounter{

    uint256 public counter; // everyone can see "counter"

    function click() public {
        counter++;

    }
}



