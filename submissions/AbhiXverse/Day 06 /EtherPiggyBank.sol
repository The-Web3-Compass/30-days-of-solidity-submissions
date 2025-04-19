// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

contract EtherPiggyBank {

    address public owner;

    // mapping to track each user's balance
    mapping(address => uint256) public balance;

    // events to log deposits and withdrawals
    event deposited(address indexed user, uint256 amount);
    event withdrawn(address indexed user, uint256 amount);

    // constructor to set the owner of the contract
    constructor() {
        owner = msg.sender;
    }

    // modifier to restrict access to the owner
    modifier admin() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // function to deposit ether into the contract
    function deposit() public payable {
        require(msg.value > 0, "insufficient balance");
        balance[msg.sender] += msg.value;
        emit deposited(msg.sender, msg.value);
    }
    
    // function to withdraw ether from the contract
    function withdraw(uint256 amount) public{
        require(balance[msg.sender] >= amount, "Not enough balance");
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit withdrawn(msg.sender, amount);
    }

    // check your balance
    function checkMyBalance() public view returns (uint256) {
        return balance[msg.sender];
    }

    // check contract balance
    function checkContractbalance() public view returns (uint256) {
        return address(this).balance;
    }

    // receive Eth sent without function call
    receive() external payable {
        balance[msg.sender] += msg.value;
        emit deposited(msg.sender, msg.value);
    }

    // fallback for unexpected calls
    fallback() external payable {
        balance[msg.sender] += msg.value;
        emit deposited(msg.sender, msg.value);
    }

}
