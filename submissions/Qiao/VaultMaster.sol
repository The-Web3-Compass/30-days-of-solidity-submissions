
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

//import "./Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract VaultMaster is Ownable{
        constructor() Ownable(msg.sender) {}

    event DepositSuccess (address indexed _address, uint256 _amount);
    event WithdrawSuccess (address indexed _address, uint256 _amount);

    function getBalance () public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function deposit () public payable {
        require(msg.value > 0, "You must send some ETH");
        emit DepositSuccess(msg.sender, msg.value);
    }

    function withdraw (uint256 _amount) public payable onlyOwner {
        require(_amount <= getBalance(), "Invalid amount.");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed.");
        emit WithdrawSuccess(msg.sender, _amount);

    }
}