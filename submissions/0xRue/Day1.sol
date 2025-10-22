// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ClickCounter {
    uint256 public counter;

    function click() public {
        counter++;
    }

    function reset() public {
        counter = 0;
    }

    function decrese() public {
        if (counter > 0){
            counter--;
        }
    } 

    function getCounter() public view returns (uint256) {
        return counter;
    }

    function clickMultiple(uint256 times) public {
        require(times > 0, "times must be positive");//错误提示文本
        counter += times;
    }
        
}

