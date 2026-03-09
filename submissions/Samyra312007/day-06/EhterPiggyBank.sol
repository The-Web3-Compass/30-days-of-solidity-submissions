//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

contract EtherPiggyBank{
    mapping(address => uint256) public bankBal;

    event Deposit(address user, uint256 amount);
    event Withdrawn(address user, uint256 amount);

    function depositBalance() public payable{
        require(msg.value > 0, "Send some Ether");
        bankBal[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawBalance(uint256 _amount) public{
        require(bankBal[msg.sender] >= _amount, "Insufficient Balance");
        bankBal[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(msg.sender, _amount);
    }

    function checkBalance() public view returns (uint256){
        return bankBal[msg.sender];
    }
}