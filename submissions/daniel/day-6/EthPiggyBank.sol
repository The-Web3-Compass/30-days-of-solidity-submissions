// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

contract EthPiggyBank {

    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}