// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { Ownable } from "./Ownable.sol";

/**
 * @title MasterKey
 * @dev Build a secure Vault contract that only the owner (master key holder) can control.
 * You'll split your logic into two parts: a reusable 'Ownable' base contract and a 'VaultMaster' contract that inherits from it.
 * Only the owner can withdraw funds or transfer ownership. This shows how to use Solidity's inheritance model to write clean,
 * reusable access control patterns — just like in real-world production contracts.
 * It's like building a secure digital safe where only the master key holder can access or delegate control.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 11
 */
contract MasterKey is Ownable {
    enum VaultAction {
        DEPOSIT,
        WITHDRAW
    }

    event VaultActivity(address indexed account, VaultAction action, uint256 amount);

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "amount must be more than zero");
        _;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function deposit() public payable nonZeroAmount(msg.value) {
        emit VaultActivity(msg.sender, VaultAction.DEPOSIT, msg.value);
    }

    function withdraw(address payable recipient, uint256 amount) public payable nonZeroAmount(amount) onlyOwner {
        require(amount <= getBalance(), "amount must be less than vault balance");
        (bool transferSuccess,) = recipient.call{ value: amount }("");
        require(transferSuccess, "tranfer failed");
        emit VaultActivity(msg.sender, VaultAction.WITHDRAW, msg.value);
    }
}
