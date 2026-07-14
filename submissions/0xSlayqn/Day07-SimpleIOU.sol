// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleIOU {
    mapping(address => uint) public balances;

    // Tracks how much each user owes to another user (who owes whom and how much)
    mapping(address => mapping(address => uint)) public debts;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    //this function records a new debt
    function createIOU(address _to, uint _amount) public payable {
        require(msg.sender != _to, "Can't Lend themselves");
        debts[msg.sender][_to] += _amount;
    }

    function repayDebt(address _to, uint _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(debts[msg.sender][_to] >= _amount, "Debt too low");
        // Pay debt using sender's balance
        balances[msg.sender] -= _amount;
        debts[msg.sender][_to] -= _amount;
        payable(_to).transfer(_amount);
    }

    function withdraw(uint _amount) external {
        require(_amount > 0, "amount should be higher than zero");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }
}
