// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

contract VaultMaster is Ownable {

    uint256 balance;

    function depositFunds(uint256 amount) public {
        require (amount > 0, "Enter a number above 0");

        balance += amount;
    }

    function withdrawFunds(uint256 amount) public onlyOwner{
        require (amount > 0, "Enter a number above 0");

        balance -= amount;

        (bool success, ) = msg.sender.call{ value:amount }("");
        require (success, "Transaction failed");
    }

    function getBalance() public view returns (uint256){
        return balance;
    }
}