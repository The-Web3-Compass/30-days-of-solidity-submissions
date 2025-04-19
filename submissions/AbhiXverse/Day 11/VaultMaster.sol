// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import "./Ownable.sol";

contract VaultMaster is Ownable {

    event Desposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);


    function desposit() public payable {
        require (msg.value > 0,"Deposit value should be greater than 0");
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(address _to, address _amount) public Admin  {
        require(_amount <= getBalance(), "Insufficient balance");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed");
        emit Withdrawal(_to, _amount);
 }


}