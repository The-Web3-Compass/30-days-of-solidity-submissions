// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract EtherPiggyBank {


    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);

    mapping(address => uint) public balances;

    function depositEth() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdrawEth() external {
        uint amount = balances[msg.sender];
        require(amount > 0, "No Ether to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }


    function getMyBalance() external view returns (uint) {
    return balances[msg.sender];
    }

}
