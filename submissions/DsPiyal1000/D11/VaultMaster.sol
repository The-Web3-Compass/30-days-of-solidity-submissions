// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; 

import "./Ownable.sol";

contract VaultMaster is Ownable {
    error InsufficientBalance();
    error InvalidRecipient();
    error DepositTooLow();
    error WithdrawFailed();

    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        if (msg.value == 0) revert DepositTooLow();
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
        if (_to == address(0)) revert InvalidRecipient();
        if (_amount > getBalance()) revert InsufficientBalance();

        uint256 balanceBefore = address(this).balance;
        (bool success, ) = payable(_to).call{value: _amount}("");
        if (!success || address(this).balance != balanceBefore - _amount) {
            revert WithdrawFailed();
        }
        emit WithdrawSuccessful(_to, _amount);
    }
}