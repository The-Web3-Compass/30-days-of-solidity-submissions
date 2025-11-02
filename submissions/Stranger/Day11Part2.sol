// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day11Part1.sol";

contract VaultMaster is Ownable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed account, uint256 value);

    // 查询余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 存款
    function deposit() public payable {
        require(msg.value > 0, "Invalid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    // 取款
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid amount");
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed");
        emit WithdrawSuccessful(_to, _amount);
    }
}