// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleIOU {

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public debts;

    function deposit() public payable {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
    }

    function recordDebt(address creditor, uint256 amount) public {
        require(creditor != msg.sender);
        require(amount > 0);
        debts[msg.sender][creditor] += amount;
    }

    function repayDebt(address payable creditor, uint256 amount) public {
        require(debts[msg.sender][creditor] >= amount);
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;
        debts[msg.sender][creditor] -= amount;

        creditor.transfer(amount);
    }

    function getDebt(address debtor, address creditor) public view returns(uint256) {
        return debts[debtor][creditor];
    }
}