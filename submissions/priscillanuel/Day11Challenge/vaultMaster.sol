// SPDX-License-Identifier: MIT
// child contract
pragma solidity ^0.8.18;

import {ownable} from "./ownable.sol";

contract vaultMaster is ownable {
    event depositSuccessful(address indexed account, uint256 value);
    event withdrawSuccessful(address indexed recipient, uint256 value);

    function deposit() public payable {
        require(msg.value > 0, "enter a valid amount");
        emit depositSuccessful(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= getBalance(), "not enough balance");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "transfer failed");
        emit withdrawSuccessful(_to, _amount);
    }
}
