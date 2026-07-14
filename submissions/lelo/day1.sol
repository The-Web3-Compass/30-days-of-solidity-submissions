// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract ClickCounter{
	uint256 public count = 0;

	function click() public{
		count++;
	}

	function decrement() public{
		count--;
	}
}