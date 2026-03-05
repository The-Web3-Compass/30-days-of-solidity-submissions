// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ClickCounter{
    uint256 public num;

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

}