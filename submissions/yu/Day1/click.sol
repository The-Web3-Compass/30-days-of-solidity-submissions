// SPDX-License-Identifier:MIT
pragma solidity ^0.8;

contract Clickcounter {
	uint256 public counter;

function click() public {
		counter++;
	}

function reset() public {
		counter = 0;
	} 

function unclick () public {
		require (counter > 0, "Counter can't be zero");
		counter--;
	}	

}