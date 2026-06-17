// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ClickCounter{
    address public owner;
    uint256 public num;

    constructor() {
        owner = msg.sender;
    }

    function setnumber(uint256 number) public {
          num = number;
    }
    function clickincrease() public {
        num = num +1;
    }
    function clickdecrease() public {
       require(num > 0, "Counter cannot go negative");
        num = num -1;
    }
    function double() public {
        num = num * 2;
    }
    function square() public {
        num = num * num;
    }
    function reset() public{
       require(msg.sender==owner , "only owner can reset");
       num =0;
    }

}