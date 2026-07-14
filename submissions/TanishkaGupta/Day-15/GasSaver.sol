// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GasSaver {

    address public owner;

    // Minimal storage usage
    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    // Using calldata instead of memory to reduce gas
    function batchDeposit(uint256[] calldata amounts) external {

        uint256 length = amounts.length;

        for (uint256 i = 0; i < length; i++) {
            deposits[msg.sender] += amounts[i];
        }

        emit Deposited(msg.sender, deposits[msg.sender]);
    }

    // Using memory for temporary computation
    function calculateTotal(uint256[] calldata numbers) external pure returns (uint256 total) {

        uint256 length = numbers.length;

        for (uint256 i = 0; i < length; i++) {
            total += numbers[i];
        }
    }

    // Withdraw stored balance
    function withdraw() external {

        uint256 amount = deposits[msg.sender];

        require(amount > 0, "No balance");

        deposits[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    // View balance
    function getBalance(address user) external view returns (uint256) {
        return deposits[user];
    }
}