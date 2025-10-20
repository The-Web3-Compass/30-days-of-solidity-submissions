//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract ClickCounter{
uint256 public counter;
function click() public {
    counter++;
}

function clickMultiple(uint256 times) public {
    counter += times;
}

function decrease() public {
    counter = counter -1;
}

function reset() public {
    counter = 0;
}

function getCounter() public view returns (uint256){
    return counter + 100;
}

}