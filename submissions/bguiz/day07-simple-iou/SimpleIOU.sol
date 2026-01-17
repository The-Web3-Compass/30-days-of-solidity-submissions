// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title SimpleIOU
 * @dev Build a simple IOU contract for a private group of friends.
 * Each user can deposit ETH, track personal balances, log who owes who, and settle debts — all on-chain.
 * You’ll learn how to accept real Ether using `payable`, transfer funds between addresses,
 * and use nested mappings to represent relationships like 'Alice owes Bob'.
 * This contract mirrors real-world borrowing and lending, and teaches you how to model those interactions in Solidity.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 7
 */
contract SimpleIOU {
    address public manager;
    uint256 public totalOwed = 0;
    uint256 public totalTransacted = 0;
    mapping(address => bool) public members;
    // ious[debtor][creditor] = amount
    mapping(address => mapping(address => uint256)) public ious;

    constructor() {
        manager = msg.sender;
        members[manager] = true;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager is allowed to perform this action");
        _;
    }

    modifier onlyMember(address a) {
        require(members[a], "only a member is allowed to perform or be party to this action");
        _;
    }

    modifier nonZeroAmount() {
        require(msg.value > 0, "non-zero amount required");
        _;
    }

    function addMember(address member) public onlyManager {
        members[member] = true;
    }

    function removeMember(address member) public onlyManager {
        members[member] = false;
    }

    // creditor sends money to debtor, logging an increment in the IOUs mapping
    function newIou(address payable debtor) public payable nonZeroAmount onlyMember(msg.sender) onlyMember(debtor) {
        address creditor = msg.sender;
        totalOwed += msg.value;
        totalTransacted += msg.value;
        ious[debtor][creditor] += msg.value;
        debtor.transfer(msg.value);
    }
    
    // debtor sends money to creditor, logging an decrement in the IOUs mapping
    function settleIou(address payable creditor) public payable nonZeroAmount onlyMember(msg.sender) onlyMember(creditor) {
        address debtor = msg.sender;
        totalOwed -= msg.value;
        totalTransacted += msg.value;
        ious[debtor][creditor] -= msg.value;
        creditor.transfer(msg.value);
    }

    function getIou(address debtor, address creditor) public view onlyMember(debtor) onlyMember(creditor) returns(uint256 amount) {
        amount = ious[debtor][creditor];
    }
}
