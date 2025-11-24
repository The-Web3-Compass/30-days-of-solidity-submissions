// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
    mapping(address => uint256) private balances;

    function deposit() external payable {
        require(msg.value > 0, "Must send Ether to deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No Ether to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getTotalBankBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
