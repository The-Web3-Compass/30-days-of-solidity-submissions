// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FriendsIOU {

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;


    event Deposited(address indexed user, uint256 amount);
    event DebtRecorded(address indexed debtor, address indexed creditor, uint256 amount);
    event DebtSettled(address indexed debtor, address indexed creditor, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH to deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function recordDebt(address to, uint256 amount) external {
        require(to != msg.sender, "Cannot owe yourself");
        debts[msg.sender][to] += amount;
        emit DebtRecorded(msg.sender, to, amount);
    }

    function settleDebt(address to, uint256 amount) external {
        require(debts[msg.sender][to] >= amount, "Debt amount too high");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;
        debts[msg.sender][to] -= amount;

        emit DebtSettled(msg.sender, to, amount);
    }


    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function totalDebtOwed(address debtor) external view returns (uint256 total) {
        for (uint i = 0; i < friends.length; i++) {
            total += debts[debtor][friends[i]];
        }
    }

    address[] public friends;

    function addFriend(address friend) external {
        friends.push(friend);
    }
}