// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SendSomeTokens {

    // Mapping to store token balances
    mapping(address => uint) public balances;

    // Deposit tokens into the contract
    function deposit() public payable {
        require(msg.value > 0, "Must send some ether");

        balances[msg.sender] += msg.value;
    }

    // Send tokens to another user
    function sendTokens(address _to, uint _amount) public {

        require(_to != address(0), "Invalid address");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    // Withdraw tokens from contract
    function withdraw(uint _amount) public {

        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Transfer failed");
    }

    // Check balance
    function getBalance(address _user) public view returns (uint) {
        return balances[_user];
    }
}