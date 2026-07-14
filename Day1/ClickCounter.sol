//SPDX-License-Identifier : MIT
pragma solidity ^0.8.20;

contract Clickcounter {
	uint256 public counter;
	
function click() public {
		counter++;
	}

function reset() public {
		counter = 0;
	} 

function decrement () public {
		require (counter > 0, "Counter can't be neg");
		counter--;
	}	

}