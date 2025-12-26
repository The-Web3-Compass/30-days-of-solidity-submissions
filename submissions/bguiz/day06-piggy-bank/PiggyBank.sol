// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title PiggyBank
 * @dev Let's make a digital piggy bank! Users can deposit and withdraw Ether (the cryptocurrency).
 * You'll learn how to manage balances (using `address` to identify users) and track who sent Ether (using `msg.sender`).
 * It's like a simple bank account on the blockchain, demonstrating how to handle Ether and user addresses.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 6
 */
contract PiggyBank {
    uint256 public constant MINIMUM_DEPOSIT = 1000;
    address public manager;
    mapping(address => bool) public members;
    mapping(address => uint256) public balances;

    constructor() {
        manager = msg.sender;
        members[manager] = true;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager is allowed to perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "only a member is allowed to perform this action");
        _;
    }

    function addMember(address member) public onlyManager {
        members[member] = true;
    }

    function removeMember(address member) public onlyManager {
        members[member] = false;
    }

    function deposit() public payable onlyMember {
        require(msg.value >= MINIMUM_DEPOSIT, "amount is less than minimum deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public onlyMember {
        require(balances[msg.sender] >= amount, "insufficient balance for this withdrawal amount");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getTotal() public view returns(uint256 total) {
        total = address(this).balance;
    }
}
